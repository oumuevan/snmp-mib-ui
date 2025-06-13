package services

import (
	"bytes"
	"fmt"
	"strings"
	"text/template"

	"github.com/go-redis/redis/v8"
	"gorm.io/gorm"

	"mib-platform/models"
)

type ConfigService struct {
	db    *gorm.DB
	redis *redis.Client
}

func NewConfigService(db *gorm.DB, redis *redis.Client) *ConfigService {
	return &ConfigService{
		db:    db,
		redis: redis,
	}
}

func (s *ConfigService) GetConfigs(page, limit int, configType string) ([]models.Config, int64, error) {
	var configs []models.Config
	var total int64

	query := s.db.Model(&models.Config{})

	if configType != "" {
		query = query.Where("type = ?", configType)
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * limit
	if err := query.Preload("Device").Preload("Template").Offset(offset).Limit(limit).Find(&configs).Error; err != nil {
		return nil, 0, err
	}

	return configs, total, nil
}

func (s *ConfigService) GetConfig(id uint) (*models.Config, error) {
	var config models.Config
	if err := s.db.Preload("Device").Preload("Template").Preload("Versions").First(&config, id).Error; err != nil {
		return nil, err
	}
	return &config, nil
}

func (s *ConfigService) CreateConfig(config *models.Config) error {
	return s.db.Create(config).Error
}

func (s *ConfigService) UpdateConfig(id uint, updates *models.Config) (*models.Config, error) {
	var config models.Config
	if err := s.db.First(&config, id).Error; err != nil {
		return nil, err
	}

	if err := s.db.Model(&config).Updates(updates).Error; err != nil {
		return nil, err
	}

	return &config, nil
}

func (s *ConfigService) DeleteConfig(id uint) error {
	return s.db.Delete(&models.Config{}, id).Error
}

func (s *ConfigService) GenerateConfig(configType string, deviceID, templateID *uint, oids []string, options map[string]interface{}) (*models.Config, error) {
	var device *models.Device
	var configTemplate *models.ConfigTemplate

	// Load device if specified
	if deviceID != nil {
		if err := s.db.Preload("Credentials").First(&device, *deviceID).Error; err != nil {
			return nil, fmt.Errorf("device not found: %v", err)
		}
	}

	// Load template if specified
	if templateID != nil {
		if err := s.db.First(&configTemplate, *templateID).Error; err != nil {
			return nil, fmt.Errorf("template not found: %v", err)
		}
	} else {
		// Use default template for the config type
		if err := s.db.Where("type = ? AND is_default = ?", configType, true).First(&configTemplate).Error; err != nil {
			return nil, fmt.Errorf("no default template found for type: %s", configType)
		}
	}

	// Generate configuration content
	content, err := s.generateConfigContent(configTemplate, device, oids, options)
	if err != nil {
		return nil, err
	}

	// Create config record
	config := &models.Config{
		Name:       fmt.Sprintf("%s_config_%d", configType, device.ID),
		Type:       configType,
		Content:    content,
		DeviceID:   deviceID,
		TemplateID: &configTemplate.ID,
		Status:     "generated",
		Version:    "1.0",
	}

	if err := s.CreateConfig(config); err != nil {
		return nil, err
	}

	return config, nil
}

func (s *ConfigService) ValidateConfig(id uint) (map[string]interface{}, error) {
	config, err := s.GetConfig(id)
	if err != nil {
		return nil, err
	}

	errors := []string{}
	warnings := []string{}

	// Basic validation
	if config.Content == "" {
		errors = append(errors, "Configuration content is empty")
	}

	// Validate based on config type
	switch config.Type {
	case "snmp":
		errors, warnings = s.validateSNMPConfig(config.Content, errors, warnings)
	case "device":
		errors, warnings = s.validateDeviceConfig(config.Content, errors, warnings)
	case "template":
		errors, warnings = s.validateTemplateConfig(config.Content, errors, warnings)
	default:
		warnings = append(warnings, fmt.Sprintf("Unknown configuration type: %s", config.Type))
	}

	// Check if device exists (if device_id is set)
	if config.DeviceID != nil {
		var device models.Device
		if err := s.db.First(&device, *config.DeviceID).Error; err != nil {
			errors = append(errors, fmt.Sprintf("Referenced device (ID: %d) not found", *config.DeviceID))
		}
	}

	// Check if template exists (if template_id is set)
	if config.TemplateID != nil {
		var template models.ConfigTemplate
		if err := s.db.First(&template, *config.TemplateID).Error; err != nil {
			errors = append(errors, fmt.Sprintf("Referenced template (ID: %d) not found", *config.TemplateID))
		}
	}

	result := map[string]interface{}{
		"valid":    len(errors) == 0,
		"errors":   errors,
		"warnings": warnings,
	}

	return result, nil
}

func (s *ConfigService) GetTemplates(configType string) ([]models.ConfigTemplate, error) {
	var templates []models.ConfigTemplate
	query := s.db.Model(&models.ConfigTemplate{})

	if configType != "" {
		query = query.Where("type = ?", configType)
	}

	if err := query.Find(&templates).Error; err != nil {
		return nil, err
	}

	return templates, nil
}

func (s *ConfigService) CreateTemplate(template *models.ConfigTemplate) error {
	return s.db.Create(template).Error
}

func (s *ConfigService) GetConfigVersions(configID uint) ([]models.ConfigVersion, error) {
	var versions []models.ConfigVersion
	if err := s.db.Where("config_id = ?", configID).Order("created_at DESC").Find(&versions).Error; err != nil {
		return nil, err
	}
	return versions, nil
}

func (s *ConfigService) CompareConfigs(config1, config2, configType string) (map[string]interface{}, error) {
	// Simple line-by-line comparison
	lines1 := strings.Split(config1, "\n")
	lines2 := strings.Split(config2, "\n")

	var additions []string
	var deletions []string
	var modifications []string

	// Basic diff algorithm (simplified)
	maxLen := len(lines1)
	if len(lines2) > maxLen {
		maxLen = len(lines2)
	}

	for i := 0; i < maxLen; i++ {
		var line1, line2 string
		if i < len(lines1) {
			line1 = lines1[i]
		}
		if i < len(lines2) {
			line2 = lines2[i]
		}

		if line1 != line2 {
			if line1 == "" {
				additions = append(additions, fmt.Sprintf("+ %s", line2))
			} else if line2 == "" {
				deletions = append(deletions, fmt.Sprintf("- %s", line1))
			} else {
				modifications = append(modifications, fmt.Sprintf("~ %s -> %s", line1, line2))
			}
		}
	}

	return map[string]interface{}{
		"additions":     additions,
		"deletions":     deletions,
		"modifications": modifications,
		"stats": map[string]int{
			"total_changes": len(additions) + len(deletions) + len(modifications),
			"additions":     len(additions),
			"deletions":     len(deletions),
			"modifications": len(modifications),
		},
	}, nil
}

func (s *ConfigService) generateConfigContent(tmpl *models.ConfigTemplate, device *models.Device, oids []string, options map[string]interface{}) (string, error) {
	// Prepare template data
	data := map[string]interface{}{
		"Device":  device,
		"OIDs":    oids,
		"Options": options,
	}

	// Parse and execute template
	t, err := template.New("config").Parse(tmpl.Template)
	if err != nil {
		return "", fmt.Errorf("failed to parse template: %v", err)
	}

	var buf bytes.Buffer
	if err := t.Execute(&buf, data); err != nil {
		return "", fmt.Errorf("failed to execute template: %v", err)
	}

	return buf.String(), nil
}

// validateSNMPConfig validates SNMP configuration content
func (s *ConfigService) validateSNMPConfig(content string, errors, warnings []string) ([]string, []string) {
	// Check for required SNMP fields
	if !strings.Contains(content, "community") && !strings.Contains(content, "username") {
		errors = append(errors, "SNMP configuration must contain either community string or username")
	}

	if strings.Contains(content, "version") {
		if !strings.Contains(content, "v1") && !strings.Contains(content, "v2c") && !strings.Contains(content, "v3") {
			warnings = append(warnings, "SNMP version should be v1, v2c, or v3")
		}
	} else {
		warnings = append(warnings, "SNMP version not specified, defaulting to v2c")
	}

	return errors, warnings
}

// validateDeviceConfig validates device configuration content
func (s *ConfigService) validateDeviceConfig(content string, errors, warnings []string) ([]string, []string) {
	// Check for required device fields
	if !strings.Contains(content, "ip_address") && !strings.Contains(content, "hostname") {
		errors = append(errors, "Device configuration must contain either ip_address or hostname")
	}

	if !strings.Contains(content, "port") {
		warnings = append(warnings, "Port not specified, will use default SNMP port 161")
	}

	return errors, warnings
}

// validateTemplateConfig validates template configuration content
func (s *ConfigService) validateTemplateConfig(content string, errors, warnings []string) ([]string, []string) {
	// Check for template syntax
	if !strings.Contains(content, "{{") || !strings.Contains(content, "}}") {
		warnings = append(warnings, "Template does not contain any placeholders")
	}

	// Check for common template variables
	commonVars := []string{"{{device_id}}", "{{timestamp}}", "{{oid_list}}"}
	foundVars := 0
	for _, v := range commonVars {
		if strings.Contains(content, v) {
			foundVars++
		}
	}

	if foundVars == 0 {
		warnings = append(warnings, "Template does not use any common variables")
	}

	return errors, warnings
}
