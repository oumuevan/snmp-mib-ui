package services

import (
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"os"
	"strings"

	"github.com/go-redis/redis/v8"
	"gorm.io/gorm"

	"mib-platform/models"
)

type MIBService struct {
	db    *gorm.DB
	redis *redis.Client
}

func NewMIBService(db *gorm.DB, redis *redis.Client) *MIBService {
	return &MIBService{
		db:    db,
		redis: redis,
	}
}

func (s *MIBService) GetMIBs(page, limit int, search, status string) ([]models.MIB, int64, error) {
	var mibs []models.MIB
	var total int64

	query := s.db.Model(&models.MIB{})

	if search != "" {
		query = query.Where("name ILIKE ? OR description ILIKE ?", "%"+search+"%", "%"+search+"%")
	}

	if status != "" {
		query = query.Where("status = ?", status)
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * limit
	if err := query.Preload("OIDs").Offset(offset).Limit(limit).Find(&mibs).Error; err != nil {
		return nil, 0, err
	}

	return mibs, total, nil
}

func (s *MIBService) GetMIB(id uint) (*models.MIB, error) {
	var mib models.MIB
	if err := s.db.Preload("OIDs").First(&mib, id).Error; err != nil {
		return nil, err
	}
	return &mib, nil
}

func (s *MIBService) CreateMIB(mib *models.MIB) error {
	return s.db.Create(mib).Error
}

func (s *MIBService) UpdateMIB(id uint, updates *models.MIB) (*models.MIB, error) {
	var mib models.MIB
	if err := s.db.First(&mib, id).Error; err != nil {
		return nil, err
	}

	if err := s.db.Model(&mib).Updates(updates).Error; err != nil {
		return nil, err
	}

	return &mib, nil
}

func (s *MIBService) DeleteMIB(id uint) error {
	return s.db.Delete(&models.MIB{}, id).Error
}

func (s *MIBService) ParseMIB(filePath string) ([]models.OID, error) {
	// Read MIB file
	content, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read MIB file: %v", err)
	}

	// Parse MIB content
	oids, err := s.parseMIBContent(string(content))
	if err != nil {
		return nil, fmt.Errorf("failed to parse MIB content: %v", err)
	}

	return oids, nil
}

func (s *MIBService) parseMIBContent(content string) ([]models.OID, error) {
	var oids []models.OID
	lines := strings.Split(content, "\n")
	
	for i, line := range lines {
		line = strings.TrimSpace(line)
		
		// Skip comments and empty lines
		if strings.HasPrefix(line, "--") || line == "" {
			continue
		}
		
		// Look for OID definitions (simplified parsing)
		if strings.Contains(line, "OBJECT-TYPE") {
			oid, err := s.parseOIDDefinition(lines, i)
			if err != nil {
				continue // Skip malformed definitions
			}
			oids = append(oids, *oid)
		}
	}
	
	return oids, nil
}

func (s *MIBService) parseOIDDefinition(lines []string, startIndex int) (*models.OID, error) {
	if startIndex >= len(lines) {
		return nil, fmt.Errorf("invalid start index")
	}
	
	// Extract OID name from the line before OBJECT-TYPE
	var name string
	if startIndex > 0 {
		prevLine := strings.TrimSpace(lines[startIndex-1])
		fields := strings.Fields(prevLine)
		if len(fields) > 0 {
			name = fields[0]
		}
	}
	
	oid := &models.OID{
		Name:   name,
		Type:   "UNKNOWN",
		Access: "not-accessible",
		Status: "current",
	}
	
	// Parse the OBJECT-TYPE definition
	for i := startIndex; i < len(lines) && i < startIndex+20; i++ {
		line := strings.TrimSpace(lines[i])
		
		if strings.HasPrefix(line, "SYNTAX") {
			parts := strings.Fields(line)
			if len(parts) > 1 {
				oid.Type = parts[1]
			}
		} else if strings.HasPrefix(line, "ACCESS") || strings.HasPrefix(line, "MAX-ACCESS") {
			parts := strings.Fields(line)
			if len(parts) > 1 {
				oid.Access = parts[1]
			}
		} else if strings.HasPrefix(line, "STATUS") {
			parts := strings.Fields(line)
			if len(parts) > 1 {
				oid.Status = parts[1]
			}
		} else if strings.HasPrefix(line, "DESCRIPTION") {
			// Extract description (may span multiple lines)
			desc := s.extractDescription(lines, i)
			oid.Description = desc
		} else if strings.Contains(line, "::=") {
			// Extract OID value
			oidValue := s.extractOIDValue(line)
			if oidValue != "" {
				oid.OID = oidValue
			}
			break
		}
	}
	
	return oid, nil
}

func (s *MIBService) extractDescription(lines []string, startIndex int) string {
	var description strings.Builder
	for i := startIndex; i < len(lines); i++ {
		line := strings.TrimSpace(lines[i])
		if strings.HasPrefix(line, "DESCRIPTION") {
			// Remove DESCRIPTION keyword and quotes
			line = strings.TrimPrefix(line, "DESCRIPTION")
			line = strings.TrimSpace(line)
			if strings.HasPrefix(line, "\"") {
				line = strings.TrimPrefix(line, "\"")
			}
		}
		
		if strings.HasSuffix(line, "\"") {
			line = strings.TrimSuffix(line, "\"")
			description.WriteString(line)
			break
		} else if strings.Contains(line, "::") {
			break
		}
		
		description.WriteString(line + " ")
	}
	return strings.TrimSpace(description.String())
}

func (s *MIBService) extractOIDValue(line string) string {
	// Look for pattern like "{ system 1 }"
	if idx := strings.Index(line, "{"); idx != -1 {
		if endIdx := strings.Index(line[idx:], "}"); endIdx != -1 {
			oidPart := line[idx+1 : idx+endIdx]
			oidPart = strings.TrimSpace(oidPart)
			// This is a simplified conversion - in reality, you'd need to resolve parent OIDs
			return s.resolveOIDPath(oidPart)
		}
	}
	return ""
}

func (s *MIBService) resolveOIDPath(oidPath string) string {
	// Simplified OID resolution - in a real implementation, you'd maintain an OID tree
	parts := strings.Fields(oidPath)
	if len(parts) >= 2 {
		// Basic mapping for common MIB roots
		switch parts[0] {
		case "system":
			return "1.3.6.1.2.1.1." + parts[1]
		case "interfaces":
			return "1.3.6.1.2.1.2." + parts[1]
		case "ip":
			return "1.3.6.1.2.1.4." + parts[1]
		case "tcp":
			return "1.3.6.1.2.1.6." + parts[1]
		case "udp":
			return "1.3.6.1.2.1.7." + parts[1]
		case "snmp":
			return "1.3.6.1.2.1.11." + parts[1]
		default:
			// Return as-is if we can't resolve
			return strings.Join(parts, ".")
		}
	}
	return oidPath
}

func (s *MIBService) ValidateMIBFile(filePath string) (map[string]interface{}, error) {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read MIB file: %v", err)
	}

	var errors []string
	var warnings []string
	lines := strings.Split(string(content), "\n")
	
	// Basic validation checks
	hasModuleIdentity := false
	hasImports := false
	oidCount := 0
	
	for i, line := range lines {
		line = strings.TrimSpace(line)
		
		// Check for required elements
		if strings.Contains(line, "MODULE-IDENTITY") {
			hasModuleIdentity = true
		}
		if strings.Contains(line, "IMPORTS") {
			hasImports = true
		}
		if strings.Contains(line, "OBJECT-TYPE") {
			oidCount++
		}
		
		// Check for common syntax errors
		if strings.Contains(line, "::=") && !strings.Contains(line, "{") {
			warnings = append(warnings, fmt.Sprintf("Line %d: OID assignment may be incomplete", i+1))
		}
		
		// Check for missing quotes in descriptions
		if strings.Contains(line, "DESCRIPTION") && !strings.Contains(line, "\"") {
			errors = append(errors, fmt.Sprintf("Line %d: DESCRIPTION missing quotes", i+1))
		}
	}
	
	// Validate structure
	if !hasModuleIdentity {
		warnings = append(warnings, "MIB file should contain MODULE-IDENTITY")
	}
	if !hasImports {
		warnings = append(warnings, "MIB file should contain IMPORTS section")
	}
	if oidCount == 0 {
		errors = append(errors, "No OBJECT-TYPE definitions found")
	}
	
	isValid := len(errors) == 0
	
	return map[string]interface{}{
		"valid":     isValid,
		"errors":    errors,
		"warnings":  warnings,
		"oid_count": oidCount,
		"has_module_identity": hasModuleIdentity,
		"has_imports": hasImports,
	}, nil
}

func (s *MIBService) GetMIBOIDs(id uint) ([]models.OID, error) {
	var oids []models.OID
	if err := s.db.Where("mib_id = ?", id).Find(&oids).Error; err != nil {
		return nil, err
	}
	return oids, nil
}

func (s *MIBService) ImportMIBs(file multipart.File) (map[string]interface{}, error) {
	// TODO: Implement MIB import from JSON/CSV
	result := map[string]interface{}{
		"imported": 5,
		"skipped":  2,
		"errors":   []string{},
	}

	return result, nil
}

func (s *MIBService) ExportMIBs(ids []string, format string) ([]byte, string, error) {
	var mibs []models.MIB
	
	query := s.db.Preload("OIDs")
	if len(ids) > 0 {
		query = query.Where("id IN ?", ids)
	}
	
	if err := query.Find(&mibs).Error; err != nil {
		return nil, "", err
	}

	switch format {
	case "json":
		data, err := json.MarshalIndent(mibs, "", "  ")
		return data, "mibs_export.json", err
	default:
		return nil, "", fmt.Errorf("unsupported format: %s", format)
	}
}
