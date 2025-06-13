"use client"

import { useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Search, ChevronRight, Info } from "lucide-react"

export default function OIDBrowserPage() {
  const [searchTerm, setSearchTerm] = useState("")

  return (
    <div className="flex-1 space-y-6 p-4 md:p-8 pt-6">
      {/* Page Header */}
      <div className="flex flex-col space-y-4 lg:flex-row lg:items-center lg:justify-between lg:space-y-0">
        <div className="space-y-1">
          <div className="flex items-center space-x-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-blue-500 to-purple-600">
              <Info className="h-4 w-4 text-white" />
            </div>
            <h2 className="text-3xl font-bold tracking-tight">OID Browser</h2>
          </div>
          <p className="text-muted-foreground">
            Browse and explore the Object Identifier (OID) tree structure
          </p>
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* OID Tree */}
        <Card>
          <CardHeader>
            <CardTitle>OID Tree</CardTitle>
            <CardDescription>Navigate through the OID hierarchy</CardDescription>
            <div className="flex items-center space-x-2">
              <Search className="h-4 w-4" />
              <Input
                placeholder="Search OIDs..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="flex-1"
              />
            </div>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex items-center space-x-2 p-2 hover:bg-accent rounded-md cursor-pointer">
                <ChevronRight className="h-4 w-4" />
                <Badge variant="outline">1</Badge>
                <span className="font-medium">iso</span>
                <span className="text-sm text-muted-foreground ml-auto">ISO assigned OIDs</span>
              </div>
              
              <div className="ml-6 space-y-2">
                <div className="flex items-center space-x-2 p-2 hover:bg-accent rounded-md cursor-pointer">
                  <ChevronRight className="h-4 w-4" />
                  <Badge variant="outline">1.3</Badge>
                  <span className="font-medium">org</span>
                  <span className="text-sm text-muted-foreground ml-auto">Organizations</span>
                </div>
                
                <div className="ml-6 space-y-2">
                  <div className="flex items-center space-x-2 p-2 hover:bg-accent rounded-md cursor-pointer">
                    <ChevronRight className="h-4 w-4" />
                    <Badge variant="outline">1.3.6</Badge>
                    <span className="font-medium">dod</span>
                    <span className="text-sm text-muted-foreground ml-auto">US Department of Defense</span>
                  </div>
                  
                  <div className="ml-6 space-y-2">
                    <div className="flex items-center space-x-2 p-2 hover:bg-accent rounded-md cursor-pointer">
                      <ChevronRight className="h-4 w-4" />
                      <Badge variant="outline">1.3.6.1</Badge>
                      <span className="font-medium">internet</span>
                      <span className="text-sm text-muted-foreground ml-auto">Internet</span>
                    </div>
                    
                    <div className="ml-6 space-y-1">
                      <div className="flex items-center space-x-2 p-2 hover:bg-accent rounded-md cursor-pointer">
                        <Badge variant="outline">1.3.6.1.1</Badge>
                        <span>directory</span>
                      </div>
                      <div className="flex items-center space-x-2 p-2 hover:bg-accent rounded-md cursor-pointer">
                        <Badge variant="outline">1.3.6.1.2</Badge>
                        <span>mgmt</span>
                      </div>
                      <div className="flex items-center space-x-2 p-2 hover:bg-accent rounded-md cursor-pointer">
                        <Badge variant="outline">1.3.6.1.3</Badge>
                        <span>experimental</span>
                      </div>
                      <div className="flex items-center space-x-2 p-2 hover:bg-accent rounded-md cursor-pointer">
                        <Badge variant="outline">1.3.6.1.4</Badge>
                        <span>private</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* OID Details */}
        <Card>
          <CardHeader>
            <CardTitle>OID Details</CardTitle>
            <CardDescription>Detailed information about the selected OID</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div>
                <h4 className="text-sm font-medium text-muted-foreground">OID</h4>
                <p className="text-lg font-mono">1.3.6.1.2.1.1.1.0</p>
              </div>
              
              <div>
                <h4 className="text-sm font-medium text-muted-foreground">Name</h4>
                <p>sysDescr</p>
              </div>
              
              <div>
                <h4 className="text-sm font-medium text-muted-foreground">Description</h4>
                <p>A textual description of the entity</p>
              </div>
              
              <div>
                <h4 className="text-sm font-medium text-muted-foreground">Type</h4>
                <Badge variant="secondary">DisplayString</Badge>
              </div>
              
              <div>
                <h4 className="text-sm font-medium text-muted-foreground">Access</h4>
                <Badge variant="outline">read-only</Badge>
              </div>
              
              <div className="pt-4">
                <Button variant="outline" size="sm">
                  <Search className="h-4 w-4 mr-2" />
                  Query this OID
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}