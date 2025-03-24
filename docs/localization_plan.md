# Localization Implementation Plan

## Directory Structure
```
src/
├── localization/
│   ├── strings/
│   │   ├── en.lua
│   │   ├── es.lua
│   │   └── ja.lua
│   ├── fonts/
│   │   ├── latin.ttf
│   │   ├── cjk.ttf
│   │   └── fallback.ttf
│   └── manager.lua
```

## Implementation

### 1. Localization Manager
Create `src/localization/manager.lua`:

```lua
local LocalizationManager = {
    currentLocale = "en",
    strings = {},
    fonts = {},
    fallbackLocale = "en"
}

function LocalizationManager:init()
    -- Load default locale
    self:loadLocale(self.currentLocale)
    -- Load fonts
    self:loadFonts()
    return self
end

function LocalizationManager:loadLocale(locale)
    local success, strings = pcall(require, "src.localization.strings." .. locale)
    if success then
        self.strings = strings
        self.currentLocale = locale
        return true
    end
    -- Fallback to English
    if locale ~= self.fallbackLocale then
        return self:loadLocale(self.fallbackLocale)
    end
    return false
end

function LocalizationManager:get(key, params)
    local str = self.strings[key] or key
    if params then
        for k, v in pairs(params) do
            str = str:gsub("{" .. k .. "}", v)
        end
    end
    return str
end

return LocalizationManager
```

### 2. String Files
Example `src/localization/strings/en.lua`:

```lua
return {
    -- Menu strings
    menu_start = "Start Game",
    menu_options = "Options",
    menu_quit = "Quit",

    -- Game strings
    food_critic_intro = "A food critic approaches...",
    score_display = "Score: {score}",
    
    -- Card strings
    card_ingredient = "{name} - Quality: {quality}",
    card_technique = "{name} ({difficulty})",
    
    -- Chef strings
    chef_greeting = "Chef {name} ready to cook!",
    
    -- Error messages
    error_save_failed = "Failed to save game",
    error_load_failed = "Could not load save file"
}
```

### 3. Font Management
Add to `src/localization/manager.lua`:

```lua
function LocalizationManager:loadFonts()
    self.fonts = {
        regular = {
            latin = love.graphics.newFont("src/localization/fonts/latin.ttf"),
            cjk = love.graphics.newFont("src/localization/fonts/cjk.ttf")
        },
        bold = {
            latin = love.graphics.newFont("src/localization/fonts/latin-bold.ttf"),
            cjk = love.graphics.newFont("src/localization/fonts/cjk-bold.ttf")
        }
    }
end

function LocalizationManager:getFont(style, size)
    local fontSet = self.fonts[style or "regular"]
    local font = self:isLatinLocale() and fontSet.latin or fontSet.cjk
    return font:setSize(size or 12)
end
```

### 4. Integration

Update `src/settings.lua`:
```lua
Settings = {
    -- ... existing settings ...
    locale = {
        current = "en",
        available = {"en", "es", "ja"},
        useSystemLocale = true
    }
}
```

Update `src/main.lua`:
```lua
function love.load()
    -- Initialize localization early
    LocalizationManager:init()
    if Settings.locale.useSystemLocale then
        LocalizationManager:setSystemLocale()
    end
end
```

## Usage Examples

### 1. In UI Components
```lua
function Menu:draw()
    love.graphics.setFont(LocalizationManager:getFont("regular", 24))
    love.graphics.print(LocalizationManager:get("menu_start"), 100, 100)
end
```

### 2. In Game Logic
```lua
function FoodCritic:introduce()
    local message = LocalizationManager:get("food_critic_intro")
    self.dialog:show(message)
end
```

### 3. With Parameters
```lua
function Card:displayName()
    return LocalizationManager:get("card_ingredient", {
        name = self.name,
        quality = self.quality
    })
end
```

## Content Guidelines

### 1. String Management
- Use descriptive keys (e.g., `menu_start` not `ms`)
- Group related strings (menu_, card_, error_)
- Include context comments
- Keep strings in respective locale files

### 2. Parameters
- Use named parameters: `{name}` not `%s`
- Document required parameters
- Provide default values when possible

### 3. Font Requirements
- Support full Unicode range
- Include fallback fonts
- Test with various string lengths
- Consider RTL languages

## Testing Plan

### 1. Automated Tests
Create `tests/localization_test.lua`:
```lua
function TestLocalization()
    -- Test string loading
    assert(LocalizationManager:get("menu_start") ~= "menu_start")
    
    -- Test parameter replacement
    local result = LocalizationManager:get("card_ingredient", {
        name = "Tomato",
        quality = "A"
    })
    assert(result:find("Tomato"))
    
    -- Test fallback
    LocalizationManager:setLocale("invalid")
    assert(LocalizationManager.currentLocale == "en")
end
```

### 2. Manual Testing
Checklist:
- [ ] UI layout with different languages
- [ ] Font rendering in all supported scripts
- [ ] Dynamic string length handling
- [ ] Special character display
- [ ] RTL text support where needed

## Implementation Schedule

### Phase 1: Basic Support
1. Implement LocalizationManager
2. Add English strings
3. Set up font system
4. Basic integration

### Phase 2: Expansion
1. Add Spanish support
2. Add Japanese support
3. Implement system locale detection
4. Add font fallbacks

### Phase 3: Polish
1. Add RTL support
2. Implement plural rules
3. Add context hints
4. Optimize font loading

## Maintenance

### 1. String Updates
Process for adding new strings:
1. Add to `en.lua`
2. Document context
3. Notify translators
4. Update all locale files

### 2. Font Updates
Regular checks for:
- Missing glyphs
- Rendering issues
- Performance metrics
- File size optimization

### 3. Quality Assurance
Regular validation of:
- String completeness
- Parameter correctness
- Font coverage
- Memory usage