# Script to update Hugo site configuration and content front matter
# Preserve navigation tags while adding separate display tags

# Configuration variables - MODIFY THESE TO MATCH YOUR SETUP
$hugoRootPath = "." # Current directory, change if needed
$configPath = Join-Path $hugoRootPath "config.toml" # Change to config.yaml if you use YAML
$contentPath = Join-Path $hugoRootPath "content"
$layoutsPath = Join-Path $hugoRootPath "layouts"
$useYaml = $true # Set to $true if your config is in YAML format

# 1. Update Hugo configuration to add navpaths taxonomy
Write-Host "Step 1: Updating Hugo configuration..."

if (Test-Path $configPath) {
    if ($configPath -like "*.yaml" -or $configPath -like "*.yml") {
        $useYaml = $true
    }

    if ($useYaml) {
        # For YAML configuration
        $config = Get-Content $configPath -Raw
        
        # Check if taxonomies section exists
        if ($config -match "taxonomies:") {
            # Add navpaths to existing taxonomies
            $config = $config -replace "taxonomies:(.*?)(\r?\n\w)", "taxonomies:$1`r`n  navpath: navpaths$2"
        } else {
            # Add new taxonomies section
            $config = $config + "`r`ntaxonomies:`r`n  tag: tags`r`n  navpath: navpaths`r`n"
        }
        
        Set-Content -Path $configPath -Value $config
    } else {
        # For TOML configuration
        $config = Get-Content $configPath -Raw
        
        # Check if taxonomies section exists
        if ($config -match "\[taxonomies\]") {
            # Add navpaths to existing taxonomies
            $config = $config -replace "(\[taxonomies\].*?)(\r?\n\[)", "`$1`r`nnavpath = `"navpaths`"`$2"
        } else {
            # Add new taxonomies section
            $config = $config + "`r`n[taxonomies]`r`ntag = `"tags`"`r`nnavpath = `"navpaths`"`r`n"
        }
        
        Set-Content -Path $configPath -Value $config
    }
    
    Write-Host "  Configuration updated successfully."
} else {
    Write-Host "  Error: Config file not found at $configPath. Please check the path." -ForegroundColor Red
    exit
}

# 2. Update content front matter to use both tags and navpaths
Write-Host "Step 2: Updating content front matter..."

$markdownFiles = Get-ChildItem -Path $contentPath -Filter "*.md" -Recurse

foreach ($file in $markdownFiles) {
    $content = Get-Content $file.FullName -Raw
    $modified = $false
    
    # Check if the file has front matter
    if ($content -match "^---\s*\r?\n(.*?)\r?\n---\s*\r?\n") {
        $frontMatter = $Matches[1]
        
        # Check if it has tags that look like ["student/academic_assistance/mentorships"]
        # Note: keeping original path format as requested
        if ($frontMatter -match "tags:\s*\[(.*?)\]") {
            $tagString = $Matches[1]
            
            # Create navpaths with the same value
            if (-not ($frontMatter -match "navpaths:")) {
                $newFrontMatter = $frontMatter -replace "tags:\s*\[(.*?)\]", "tags: [$1]`r`nnavpaths: [$1]"
                $content = $content -replace "^---\s*\r?\n(.*?)\r?\n---\s*\r?\n", "---`r`n$newFrontMatter`r`n---`r`n"
                $modified = $true
            }
        }
        
        if ($modified) {
            Set-Content -Path $file.FullName -Value $content
        }
    }
}

Write-Host "  Content front matter updated."

# 3. Find and modify navigation template
Write-Host "Step 3: Looking for navigation templates to update..."

# Look for potential navigation template files
$navTemplates = @(
    "layouts/partials/guided-navigation.html",
    "layouts/partials/navigation.html",
    "layouts/partials/sidebar-navigation.html",
    "layouts/partials/sidebar.html",
    "layouts/partials/menu.html"
)

$foundTemplate = $false

foreach ($template in $navTemplates) {
    $templatePath = Join-Path $hugoRootPath $template
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
    Write-Host "  Warning: Could not automatically find navigation templates." -ForegroundColor Yellow
    Write-Host "  You may need to manually update your navigation templates to use navpaths instead of tags." -ForegroundColor Yellow
}

Write-Host "`nScript completed. Please run 'hugo server' to test your changes." -ForegroundColor Green
Write-Host "Remember to check if your navigation still works correctly and TAG section displays as expected." -ForegroundColor Green