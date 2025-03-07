# Improved script to update Hugo site configuration and content front matter
# This version automatically detects your config file format

# Configuration variables
$hugoRootPath = "." # Current directory
$contentPath = Join-Path $hugoRootPath "content"
$layoutsPath = Join-Path $hugoRootPath "layouts"

# Step 0: Detect Hugo configuration file
Write-Host "Step 0: Detecting Hugo configuration file..."
$configFile = $null

# Look for common Hugo config file names
$possibleConfigs = @(
    "config.toml",
    "config.yaml",
    "config.yml",
    "config.json",
    "config/_default/config.toml",
    "config/_default/config.yaml",
    "config/_default/config.yml"
)

foreach ($config in $possibleConfigs) {
    $configPath = Join-Path $hugoRootPath $config
    if (Test-Path $configPath) {
        $configFile = $configPath
        Write-Host "  Found configuration file: $configFile"
        break
    }
}

# Check if we found a config file
if ($null -eq $configFile) {
    Write-Host "Error: Could not find Hugo configuration file. Please specify the path manually." -ForegroundColor Red
    $manualPath = Read-Host "Enter the path to your Hugo config file (e.g., ./hugo.toml)"
    if (Test-Path $manualPath) {
        $configFile = $manualPath
    } else {
        Write-Host "Error: The specified file does not exist. Exiting script." -ForegroundColor Red
        exit
    }
}

# Determine config format
$useYaml = $configFile -like "*.yaml" -or $configFile -like "*.yml"
$useJson = $configFile -like "*.json"

# 1. Update Hugo configuration to add navpaths taxonomy
Write-Host "Step 1: Updating Hugo configuration..."

if (Test-Path $configFile) {
    if ($useYaml) {
        # For YAML configuration
        $config = Get-Content $configFile -Raw
        
        # Check if taxonomies section exists
        if ($config -match "taxonomies:") {
            # Add navpaths to existing taxonomies if it doesn't already exist
            if (-not ($config -match "navpath:")) {
                $config = $config -replace "taxonomies:(.*?)(\r?\n\w)", "taxonomies:$1`r`n  navpath: navpaths$2"
            }
        } else {
            # Add new taxonomies section
            $config = $config + "`r`ntaxonomies:`r`n  tag: tags`r`n  navpath: navpaths`r`n"
        }
        
        Set-Content -Path $configFile -Value $config
    } 
    elseif ($useJson) {
        # For JSON configuration
        try {
            $jsonConfig = Get-Content $configFile -Raw | ConvertFrom-Json
            
            # Ensure taxonomies property exists
            if (-not (Get-Member -InputObject $jsonConfig -Name "taxonomies" -MemberType Properties)) {
                $jsonConfig | Add-Member -NotePropertyName "taxonomies" -NotePropertyValue @{
                    "tag" = "tags"
                    "navpath" = "navpaths"
                }
            } else {
                # Add navpath to existing taxonomies if needed
                if (-not (Get-Member -InputObject $jsonConfig.taxonomies -Name "navpath" -MemberType Properties)) {
                    $jsonConfig.taxonomies | Add-Member -NotePropertyName "navpath" -NotePropertyValue "navpaths"
                }
            }
            
            $jsonConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configFile
        } catch {
            Write-Host "  Error processing JSON configuration: $_" -ForegroundColor Red
            exit
        }
    }
    else {
        # For TOML configuration
        $config = Get-Content $configFile -Raw
        
        # Check if taxonomies section exists
        if ($config -match "\[taxonomies\]") {
            # Add navpaths to existing taxonomies if it doesn't already exist
            if (-not ($config -match "navpath\s*=")) {
                $config = $config -replace "(\[taxonomies\].*?)(\r?\n\[|\z)", "`$1`r`nnavpath = `"navpaths`"`$2"
            }
        } else {
            # Add new taxonomies section
            $config = $config + "`r`n[taxonomies]`r`ntag = `"tags`"`r`nnavpath = `"navpaths`"`r`n"
        }
        
        Set-Content -Path $configFile -Value $config
    }
    
    Write-Host "  Configuration updated successfully."
} else {
    Write-Host "  Error: Config file not found at $configFile. Please check the path." -ForegroundColor Red
    exit
}

# First check if the content directory exists
if (-not (Test-Path $contentPath)) {
    Write-Host "Error: Content directory not found at $contentPath." -ForegroundColor Red
    $contentPath = Read-Host "Enter the path to your content directory"
    if (-not (Test-Path $contentPath)) {
        Write-Host "Error: The specified directory does not exist. Exiting script." -ForegroundColor Red
        exit
    }
}

# 2. Update content front matter to use both tags and navpaths
Write-Host "Step 2: Updating content front matter..."

$markdownFiles = Get-ChildItem -Path $contentPath -Filter "*.md" -Recurse

$updatedFiles = 0
foreach ($file in $markdownFiles) {
    $content = Get-Content $file.FullName -Raw
    $modified = $false
    
    # Check if the file has front matter
    if ($content -match "^---\s*\r?\n(.*?)\r?\n---\s*\r?\n") {
        $frontMatter = $Matches[1]
        
        # Check if it has tags
        if ($frontMatter -match "tags:\s*\[(.*?)\]") {
            $tagString = $Matches[1]
            
            # Create navpaths with the same value if it doesn't already have navpaths
            if (-not ($frontMatter -match "navpaths:")) {
                $newFrontMatter = $frontMatter -replace "tags:\s*\[(.*?)\]", "tags: [$1]`r`nnavpaths: [$1]"
                $content = $content -replace "^---\s*\r?\n(.*?)\r?\n---\s*\r?\n", "---`r`n$newFrontMatter`r`n---`r`n"
                $modified = $true
                $updatedFiles++
            }
        }
        
        if ($modified) {
            Set-Content -Path $file.FullName -Value $content
        }
    }
}

Write-Host "  Updated $updatedFiles content files with navpaths."

# Check if layouts directory exists
if (-not (Test-Path $layoutsPath)) {
    Write-Host "Warning: Layouts directory not found at $layoutsPath." -ForegroundColor Yellow
    Write-Host "Looking for layouts in theme directory instead..."
    
    # Try to find the active theme
    $themeDir = $null
    if ($useYaml) {
        $configContent = Get-Content $configFile -Raw
        if ($configContent -match "theme:\s*[""']?(.*?)[""']?(\s|$)") {
            $themeName = $Matches[1]
            $themeDir = Join-Path $hugoRootPath "themes/$themeName"
        }
    } elseif ($useJson) {
        $jsonConfig = Get-Content $configFile -Raw | ConvertFrom-Json
        if (Get-Member -InputObject $jsonConfig -Name "theme" -MemberType Properties) {
            $themeName = $jsonConfig.theme
            $themeDir = Join-Path $hugoRootPath "themes/$themeName"
        }
    } else {
        $configContent = Get-Content $configFile -Raw
        if ($configContent -match "theme\s*=\s*[""']?(.*?)[""']?(\s|$)") {
            $themeName = $Matches[1]
            $themeDir = Join-Path $hugoRootPath "themes/$themeName"
        }
    }
    
    if ($themeDir -and (Test-Path $themeDir)) {
        $layoutsPath = Join-Path $themeDir "layouts"
        Write-Host "  Found theme layouts at: $layoutsPath"
    } else {
        Write-Host "  Could not locate layouts directory. You may need to manually update your navigation templates." -ForegroundColor Yellow
    }
}

# 3. Find and modify navigation template
if (Test-Path $layoutsPath) {
    Write-Host "Step 3: Looking for navigation templates to update..."

    # Look for potential navigation template files
    $navTemplates = @(
        "partials/guided-navigation.html",
        "partials/navigation.html",
        "partials/sidebar-navigation.html",
        "partials/sidebar.html",
        "partials/menu.html",
        "partials/nav.html",
        "partials/header.html"
    )

    $foundTemplate = $false

    foreach ($template in $navTemplates) {
        $templatePath = Join-Path $layoutsPath $template
        if (Test-Path $templatePath) {
            Write-Host "  Found potential navigation template: $template"
            
            # Read template content
            $templateContent = Get-Content $templatePath -Raw
            
            # Check if it references tags
            if ($templateContent -match "\.Params\.tags" -or $templateContent -match "\.GetTerms\s+[""']tags") {
                # Update references from tags to navpaths
                $updatedContent = $templateContent -replace "\.Params\.tags", ".Params.navpaths"
                $updatedContent = $updatedContent -replace "\.GetTerms\s+[""']tags", '.GetTerms "navpaths"'
                
                # Backup original
                Copy-Item -Path $templatePath -Destination "$templatePath.bak"
                
                # Save updated template
                Set-Content -Path $templatePath -Value $updatedContent
                
                Write-Host "  Updated navigation template: $template (backup created at $template.bak)" -ForegroundColor Green
                $foundTemplate = $true
            }
        }
    }

    if (-not $foundTemplate) {
        Write-Host "  Warning: Could not automatically find navigation templates with tag references." -ForegroundColor Yellow
        Write-Host "  You may need to manually update your navigation templates to use navpaths instead of tags." -ForegroundColor Yellow
    }
} else {
    Write-Host "Step 3: Skipped - Could not locate layouts directory."
}

Write-Host "`nScript completed. Please run 'hugo server' to test your changes." -ForegroundColor Green
Write-Host "Remember to check if your navigation still works correctly and TAG section displays as expected." -ForegroundColor Green