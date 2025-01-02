local json = require("dkjson")

function love.load()
    love.window.setMode(1000, 600, {resizable=false, vsync=true, minwidth=1000, minheight=600})

    scroll_offset = 0
    penguin_scale = 1
    penguin_clicked = false
    click_animation_duration = 0.2
    click_animation_timer = 0
    cursor_over_upgrade = false
    cursor_over_penguin = false
    cursor_over_feature = false

    main_image = love.graphics.newImage("images/mob.png")
    particule = love.graphics.newImage("images/coin.png")

    click_sound = love.sound.newSoundData("sound/click.mp3")
    click_source = love.audio.newSource(click_sound)

    coin_sound = love.sound.newSoundData("sound/coin.mp3")
    coin_source = love.audio.newSource(coin_sound)

    kaching_sound = love.sound.newSoundData("sound/kaching.mp3")
    kaching_source = love.audio.newSource(kaching_sound)

    love.graphics.setBlendMode("alpha")

    -- particules
    psystem = love.graphics.newParticleSystem(particule, 32)
    psystem:setParticleLifetime(2, 4) -- Particles live at least 1s and at most 3s.
    psystem:setLinearAcceleration(0, -200, 0, -100) -- Initial upward movement.
    psystem:setColors(255, 255, 255, 255, 255, 255, 255, 0) -- Fade to transparent.
    bg_music = love.audio.newSource('sound/bg_music.mp3', 'stream')
    bg_music:setLooping(true)
    bg_music:play()
    game_state = handleGameState()

    -- Load images for upgrades
    for _, upgrade in ipairs(game_state.upgrades) do
        upgrade.icon = love.graphics.newImage(upgrade.icon)
    end
end

function handleGameState()
    local loaded_state = nil
    if love.filesystem.getInfo("savegame.json") then
        local file = love.filesystem.read("savegame.json")
        loaded_state = json.decode(file)
    end

    if loaded_state then
        for key, value in pairs(loaded_state.features) do
            print(key, value)
        end
    end

    if loaded_state then
        for i, upgrade in ipairs(loaded_state.upgrades) do
            upgrade.icon = "images/upgrade_" .. i .. ".png"
            upgrade.bg_color = {math.random(), math.random(), math.random()}
        end
        for i, feature in ipairs(loaded_state.features) do
            feature.image = "images/feature_" .. i .. ".png"
        end
    end

    return {
        score = loaded_state and loaded_state.score or 0,
        current_mps = loaded_state and loaded_state.current_mps or 0,
        power = loaded_state and loaded_state.power or 1,

        upgrades = loaded_state and loaded_state.upgrades or {
            {name = "Dev", cost = 50, mps = 1, icon = "images/upgrade_1.png", owned = 0, bg_color={0, 0, 1}, hidden = false},
            {name = "Bureau d'études", cost = 300, mps = 5, icon = "images/upgrade_2.png", owned = 0, bg_color={0, 1, 0}, hidden = true},
            {name = "Com'", cost = 1500, mps = 25, icon = "images/upgrade_3.png", owned = 0, bg_color={1, 0, 0}, hidden = true},
            {name = "Lead Dev", cost = 7500, mps = 125, icon = "images/upgrade_4.png", owned = 0, bg_color={1, 1, 0}, hidden = true},
            {name = "PO", cost = 30000, mps = 625, icon = "images/upgrade_5.png", owned = 0, bg_color={1, 0, 1}, hidden = true},
            {name = "PDG", cost = 150000, mps = 3125, icon = "images/upgrade_6.png", owned = 0, bg_color={0, 1, 1}, hidden = true},
            {name = "Succube", cost = 500000, mps = 10000, icon = "images/upgrade_7.png", owned = 0, bg_color={0, 1, 1}, hidden = true},
        },
        features = loaded_state and loaded_state.features or {
            { name = "Supervision", cost = 500, bonus = 1.5, image = "images/feature_1.png", hidden = false, bought = false},
            { name = "Support", cost = 2000, bonus = 1.75, image = "images/feature_2.png", hidden = true, bought = false},
            { name = "App", cost = 10000, bonus = 2, image = "images/feature_3.png", hidden = true, bought = false},
            { name = "Café", cost = 50000, bonus = 2.5, image = "images/feature_4.png", hidden = true, bought = false},
            { name = "Mobilink", cost = 100000, bonus = 4, image = "images/feature_5.png", hidden = true, bought = false},
            { name = "Washoku", cost = 1000000, bonus = 5, image = "images/feature_6.png", hidden = true, bought = false},
        }
    }
end

function love.update(dt)
    game_state.score = game_state.score + game_state.current_mps * dt
    psystem:update(dt)
    checkUpgradeVisibility()

    if penguin_clicked then
        click_animation_timer = click_animation_timer + dt
        if click_animation_timer >= click_animation_duration then
            penguin_scale = 1
            penguin_clicked = false
            click_animation_timer = 0
        else
            penguin_scale = 1.2 - 0.2 * (click_animation_timer / click_animation_duration)
        end
    end

    local cursor_changed = false

    if cursor_over_upgrade or cursor_over_penguin or cursor_over_feature then
        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
        cursor_changed = true
    end

    if not cursor_changed then
        love.mouse.setCursor()
    end
end

function love.draw()
    love.graphics.clear(1, 0.75, 0.8) -- RGB values for pink background
    drawPenguin()
    drawLeftPanel()
    drawRightPanel()
    drawParticles()
end

function drawLeftPanel()
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.rectangle("fill", 0, 0, 200, love.graphics.getHeight())
    drawUpgrades()
end

function drawRightPanel()
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.rectangle("fill", love.graphics.getWidth() - 200, 0, 200, love.graphics.getHeight())
    drawSaveButton()
    drawQuitButton()
    drawScoreAndMPS()
    drawFeatures()
end

function drawQuitButton()
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", love.graphics.getWidth() - 190, love.graphics.getHeight() - 80, 180, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", love.graphics.getWidth() - 190, love.graphics.getHeight() - 80, 180, 30)
    love.graphics.setColor(0, 0, 0)
    local font = love.graphics.newFont(12)
    love.graphics.setFont(font)
    local text = "Quit Game"
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight(text)
    love.graphics.print(text, love.graphics.getWidth() - 190 + (180 - textWidth) / 2, love.graphics.getHeight() - 80 + (30 - textHeight) / 2)
end


function drawUpgrades()
    y =  drawVisibleUpgrades()
    drawNextUpgrade(y)
end
function drawFeatures()
    y = drawVisibleFeatures()
    drawNextFeature(y)
end

function drawNextFeature(y)
    love.graphics.setColor(0, 0, 0)
    font = love.graphics.newFont(12)
    love.graphics.setFont(font)
    for i, feature in ipairs(game_state.features) do
        if not feature.bought and feature.hidden then
            love.graphics.draw(love.graphics.newImage(feature.image), love.graphics.getWidth() - 190, y, 0, 0.5, 0.5) -- Scale the icon to fit in the sidebar
            
            -- Draw white rectangle
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("fill", love.graphics.getWidth() - 190, y + 50, 50, 20)
            love.graphics.setColor(0, 0, 0)

            -- Draw buy button next to the icon
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", love.graphics.getWidth() - 130, y, 120, 20)
            love.graphics.rectangle("fill", love.graphics.getWidth() - 130, y, 120, 20)

            -- Draw cost below the buy button
            cost_text = feature.cost .. " $"
            cost_text_width = font:getWidth(cost_text)
            love.graphics.print(cost_text, love.graphics.getWidth() - 130 + (120 - cost_text_width) / 2, y + 30)
            break
        end
    end
end
function drawVisibleFeatures()
    love.graphics.setColor(0, 0, 0)
    font = love.graphics.newFont(12)
    love.graphics.setFont(font)
    love.graphics.setFont(love.graphics.newFont(18)) -- Set a larger font size for the "Features" title
    love.graphics.print("Features", love.graphics.getWidth() - 190, 150)
    love.graphics.setFont(love.graphics.newFont(12)) -- Reset font size for the rest of the text
    local y = 180 -- Start drawing features from the top
    for i, feature in ipairs(game_state.features) do
        if not feature.hidden then
            love.graphics.setColor(1, 1, 1) -- Reset color to white before drawing the image
            love.graphics.draw(love.graphics.newImage(feature.image), love.graphics.getWidth() - 190, y, 0, 0.5, 0.5) -- Scale the icon to fit in the sidebar
            
            -- Draw white rectangle
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("fill", love.graphics.getWidth() - 190, y + 50, 50, 20)
            love.graphics.setColor(0, 0, 0)
            cost_text = feature.cost .. " $"
            cost_text_width = love.graphics.getFont():getWidth(cost_text)
            love.graphics.print(cost_text, love.graphics.getWidth() - 190 + (50 - cost_text_width) / 2, y + 50)

            -- Draw button next to the icon
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", love.graphics.getWidth() - 130, y, 120, 20)
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.rectangle("fill", love.graphics.getWidth() - 130, y, 120, 20)
            love.graphics.setColor(0, 0, 0)

            -- Text for the button
            name_text_width = font:getWidth(feature.name)
            love.graphics.print(feature.name, love.graphics.getWidth() - 130 + (120 - name_text_width) / 2, y)

            -- Draw bonus below the buy button
            bonus_text = "CA x" .. feature.bonus
            bonus_text_width = font:getWidth(bonus_text)
            love.graphics.print(bonus_text, love.graphics.getWidth() - 130, y + 30)

            y = y + 78 -- Move to the next position for the next feature
        end
    end
    return y
end

function drawNextUpgrade(y)
    love.graphics.setColor(0, 0, 0)
    font = love.graphics.newFont(12)
    love.graphics.setFont(font)
    y = y+100
    for i, upgrade in ipairs(game_state.upgrades) do
        if upgrade.hidden then
            love.graphics.draw(upgrade.icon, 10, y, 0, 0.5, 0.5) -- Scale the icon to fit in the sidebar
            
            -- Draw white rectangle
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("fill", 10, y + 50, 50, 20)
            love.graphics.setColor(0, 0, 0)

            -- Draw buy button next to the icon
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", 70, y, 120, 20)
            love.graphics.rectangle("fill", 70, y, 120, 20)

            -- Draw cost and mps below the buy button
            cost_text = upgrade.cost .. " $"
            cost_text_width = font:getWidth(cost_text)
            love.graphics.print(cost_text, 70, y + 30)

            mps_text = upgrade.mps .. " $/s"
            mps_text_width = font:getWidth(mps_text)
            love.graphics.print(mps_text, 190 - mps_text_width, y + 30)
            break
        end
    end
end

function drawVisibleUpgrades()
    love.graphics.setColor(0, 0, 0)
    font = love.graphics.newFont(12)
    love.graphics.setFont(font)
    for i, upgrade in ipairs(game_state.upgrades) do
        if not upgrade.hidden then
            y = 10 + (i - 1) * 78 + scroll_offset
            love.graphics.setColor(1, 1, 1) -- Reset color to white before drawing the image
            love.graphics.draw(upgrade.icon, 10, y, 0, 0.5, 0.5) -- Scale the icon to fit in the sidebar
            
            -- Draw white rectangle
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("fill", 10, y + 50, 50, 20)
            love.graphics.setColor(0, 0, 0)
            owned_text = tostring(upgrade.owned)
            owned_text_width = love.graphics.getFont():getWidth(owned_text)
            love.graphics.print(owned_text, 10 + (50 - owned_text_width) / 2, y + 50)

            -- Draw buy button next to the icon
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("line", 70, y, 120, 20)
            love.graphics.setColor(upgrade.bg_color)
            love.graphics.rectangle("fill", 70, y, 120, 20)
            love.graphics.setColor(0, 0, 0)
            name_text_width = font:getWidth(upgrade.name)
            love.graphics.print(upgrade.name, 70 + (120 - name_text_width) / 2, y)

            -- Draw cost and mps below the buy button
            cost_text = upgrade.cost .. " $"
            cost_text_width = font:getWidth(cost_text)
            love.graphics.print(cost_text, 70, y + 30)

            mps_text = upgrade.mps .. " $/s"
            mps_text_width = font:getWidth(mps_text)
            love.graphics.print(mps_text, 190 - mps_text_width, y + 30)
        end
    end
    return y
end

function drawScoreAndMPS()
    love.graphics.setColor(0, 0, 0)
    local font = love.graphics.newFont(18)
    love.graphics.setFont(font) -- Set a font size for score and MPS

    function formatScore(score)
        if not score then return "0" end
        local units = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Od", "Nd", "Vg", "Uvg", "Dvg", "Tvg", "Qavg", "Qivg", "Sxvg", "Spvg", "Ovg", "Nvg", "Tg", "Utg", "Dtg", "Ttg", "Qatg", "Qitg", "Sxtg", "Sptg", "Otg", "Ntg", "Qaa", "Qia", "Sxa", "Spa", "Oa", "Na", "Uaa", "Daa", "Taa", "Qaaa", "Qi", "Sxa", "Spa", "Oa", "Na", "Uaa", "Daa", "Taa", "Qaaa", "Qia", "Sxa", "Spa", "Oa", "Na", "Uaa", "Daa", "Taa", "Qaaa", "Qia", "Sxa", "Spa", "Oa", "Na", "Uaa", "Daa", "Taa", "Qaaa", "Qia", "Sxa", "Spa", "Oa", "Na", "Uaa", "Daa", "Taa", "Qaaa", "Qia", "Sxa", "Spa", "Oa", "Na", "Uaa", "Daa", "Taa", "Qaaa", "Qia", "Sxa", "Spa", "Oa", "Na", "Uaa", "Daa", "Taa", "Qaaa", "Qia", "Sxa", "Spa", "Oa", "Na", "Uaa", "Daa", "Taa", "Qaaa", "Qia"}
        local unit = 1
        while score >= 1000 and unit < #units do
            score = score / 1000
            unit = unit + 1
        end
        return string.format("%.2f", score) .. units[unit]
    end

    local score_text = "CA: " .. formatScore(game_state.score) .. " $"
    local mps_text = game_state.current_mps .. " $ / second"
    local power_text = game_state.power .. " $ / click"

    -- Draw a background rectangle for better readability
    love.graphics.setColor(1, 1, 1, 0.8) -- White with some transparency
    love.graphics.rectangle("fill", love.graphics.getWidth() - 196, 10, 190, 100, 10, 10) -- Rounded corners

    -- Draw score and MPS with padding
    love.graphics.setColor(0, 0, 0)
    local padding = 15
    love.graphics.print(score_text, love.graphics.getWidth() - 190 + padding, 20)
    love.graphics.print(mps_text, love.graphics.getWidth() - 190 + padding, 50)
    love.graphics.print(power_text, love.graphics.getWidth() - 190 + padding, 80)
end


function drawPenguin()
    bg_image = love.graphics.newImage("images/bg.png")
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(bg_image, 200, 0, 0, 1.5, 1.5)
    penguin_x = (love.graphics.getWidth() - main_image:getWidth() * penguin_scale / 2.5 ) / 2
    penguin_y = (love.graphics.getHeight() - main_image:getHeight() * penguin_scale / 2.5 ) / 1.8
    love.graphics.setColor(1, 1, 1) -- Reset color to white before drawing the image
    love.graphics.draw(main_image, penguin_x, penguin_y, 0, penguin_scale / 2.5, penguin_scale / 2.5)
    
    -- Draw features without being affected by penguin scale
    if game_state.features[1].bought then
        local cs_image = love.graphics.newImage("images/feature_1.png")
        love.graphics.draw(cs_image, penguin_x + 80, penguin_y + 40, 0, 1, 1)
        love.graphics.draw(cs_image, penguin_x + 50, penguin_y + 60, 0, 1, 1)
        love.graphics.draw(cs_image, penguin_x + 20, penguin_y + 80, 0, 1, 1)
    end
    if game_state.features[2].bought then
        local support_image = love.graphics.newImage("images/support_art.png")
        love.graphics.draw(support_image, penguin_x - 150, penguin_y - 40, 0, 0.7, 0.7)
    end
    if game_state.features[3].bought then
        local app_image = love.graphics.newImage("images/feature_3.png")
        love.graphics.draw(app_image, penguin_x + 200, penguin_y - 150, 0, 1, 1)
    end
    if game_state.features[4].bought then
        local cafe_image = love.graphics.newImage("images/feature_4.png")
        love.graphics.draw(cafe_image, penguin_x + 30, penguin_y - 100, 0, 1, 1)
    end
    if game_state.features[5].bought then
        local mobilink_image = love.graphics.newImage("images/feature_5.png")
        love.graphics.draw(mobilink_image, penguin_x - 200, penguin_y - 150, 0, 1, 1)
    end
    if game_state.features[6].bought then
        local washoku_image = love.graphics.newImage("images/wash.png")
        love.graphics.draw(washoku_image, penguin_x - 50, penguin_y - 300, 0, 1, 1)
    end
end

function drawParticles()
    love.graphics.setColor(1, 1, 1) -- Set color to white before drawing particles
    love.graphics.draw(psystem, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2 - 50)
end

function drawSaveButton()
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", love.graphics.getWidth() - 190, love.graphics.getHeight() - 40, 180, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", love.graphics.getWidth() - 190, love.graphics.getHeight() - 40, 180, 30)
    love.graphics.setColor(0, 0, 0)
    local font = love.graphics.newFont(12)
    love.graphics.setFont(font)
    local text = "Save Game"
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight(text)
    love.graphics.print(text, love.graphics.getWidth() - 190 + (180 - textWidth) / 2, love.graphics.getHeight() - 40 + (30 - textHeight) / 2)
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then -- left mouse button
        handlePenguinClick(x, y)
        handleUpgradeClick(x, y)
        handleFeatureClick(x, y)
        handleSaveClick(x, y)
        handleQuitClick(x, y)
    end
end

function handleQuitClick(x, y)
    if x >= love.graphics.getWidth() - 190 and x <= love.graphics.getWidth() - 10 and y >= love.graphics.getHeight() - 80 and y <= love.graphics.getHeight() - 50 then
        love.event.quit()
    end
end

function handleSaveClick(x, y)
    if x >= love.graphics.getWidth() - 190 and x <= love.graphics.getWidth() - 10 and y >= love.graphics.getHeight() - 40 and y <= love.graphics.getHeight() - 10 then
        saveGame()
    end
end

function handleFeatureClick(x, y)
    local y_position = 180
    for i, feature in ipairs(game_state.features) do
        if not feature.hidden then
            if x >= love.graphics.getWidth() - 190 and x <= love.graphics.getWidth() - 190 + 50 and y >= y_position and y <= y_position + 70 then
                if game_state.score >= feature.cost then
                    kaching_source:play()
                    game_state.current_mps = math.floor(game_state.current_mps * feature.bonus)
                    game_state.score = game_state.score - feature.cost
                    feature.hidden = true
                    feature.bought = true

                    -- Make the next feature available
                    if game_state.features[i + 1] then
                        game_state.features[i + 1].hidden = false
                    end

                    -- Make the feature after the next one the black one
                    if game_state.features[i + 2] then
                        game_state.features[i + 2].hidden = true
                    end
                end
            end
            y_position = y_position + 78
        end
    end
end


function handlePenguinClick(x, y)
    penguin_x = (love.graphics.getWidth() - main_image:getWidth() * penguin_scale) / 2
    penguin_y = (love.graphics.getHeight() - main_image:getHeight() * penguin_scale) / 2
    if x >= penguin_x and x <= penguin_x + main_image:getWidth() * penguin_scale and y >= penguin_y and y <= penguin_y + main_image:getHeight() * penguin_scale then
        game_state.score = game_state.score + game_state.power
        psystem:emit(1)
        penguin_clicked = true
        click_animation_timer = 0
        click_source:play()
    end
end

function handleUpgradeClick(x, y)
    for i, upgrade in ipairs(game_state.upgrades) do
        upgrade_y = 10 + (i - 1) * 78 + scroll_offset
        if x >= 10 and x <= 60 and y >= upgrade_y and y <= upgrade_y + 50 then
            if game_state.score >= upgrade.cost then
                coin_source:play()
                if upgrade.name == "Dev" then
                    game_state.power = game_state.power + 1
                end
                game_state.score = game_state.score - upgrade.cost
                upgrade.owned = upgrade.owned + 1
                upgrade.cost = math.floor(upgrade.cost * 1.15)
                game_state.current_mps = game_state.current_mps + upgrade.mps
            end
        end
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    handlePenguinHover(x, y)
    handleUpgradeHover(x, y)
    handleFeatureHover(x, y)
end


function handlePenguinHover(x, y)
    penguin_x = (love.graphics.getWidth() - main_image:getWidth() * penguin_scale) / 2
    penguin_y = (love.graphics.getHeight() - main_image:getHeight() * penguin_scale) / 2
    if x >= penguin_x and x <= penguin_x + main_image:getWidth() * penguin_scale and y >= penguin_y and y <= penguin_y + main_image:getHeight() * penguin_scale then
        cursor_over_penguin = true
    else
        cursor_over_penguin = false
    end
end

function handleUpgradeHover(x, y)
    cursor_over_upgrade = false
    for i, upgrade in ipairs(game_state.upgrades) do
        if not upgrade.hidden then
            upgrade_y = 10 + (i - 1) * 78 + scroll_offset
            if x >= 10 and x <= 60 and y >= upgrade_y and y <= upgrade_y + 50 then
                cursor_over_upgrade = true
                break
            end
        end
    end
end

function handleFeatureHover(x, y)
    cursor_over_feature = false
    local y_position = 180
    for i, feature in ipairs(game_state.features) do
        if not feature.hidden then
            if x >= love.graphics.getWidth() - 190 and x <= love.graphics.getWidth() - 190 + 50 and y >= y_position and y <= y_position + 70 then
                cursor_over_feature = true
                break
            end
            y_position = y_position + 78
        end
    end
end

function love.wheelmoved(x, y)
    scroll_offset = scroll_offset + y * 20
    if scroll_offset > 0 then
        scroll_offset = 0
    end
end

function checkUpgradeVisibility()
    for i, upgrade in ipairs(game_state.upgrades) do
        if game_state.score >= upgrade.cost and upgrade.hidden then
            upgrade.hidden = false
        end
    end

    for i, feature in ipairs(game_state.features) do
        if game_state.score >= feature.cost and feature.hidden and not feature.bought then
            feature.hidden = false
        end
    end
end


function sanitizedGameState()
    local sanitized_state = {}
    sanitized_state.score = game_state.score
    sanitized_state.current_mps = game_state.current_mps
    sanitized_state.power = game_state.power
    sanitized_state.upgrades = {}
    for _, upgrade in ipairs(game_state.upgrades) do
        local sanitized_upgrade = {}
        sanitized_upgrade.name = upgrade.name
        sanitized_upgrade.cost = upgrade.cost
        sanitized_upgrade.mps = upgrade.mps
        sanitized_upgrade.owned = upgrade.owned
        sanitized_upgrade.hidden = upgrade.hidden
        table.insert(sanitized_state.upgrades, sanitized_upgrade)
    end
    sanitized_state.features = {}
    for _, feature in ipairs(game_state.features) do
        local sanitized_feature = {}
        sanitized_feature.name = feature.name
        sanitized_feature.cost = feature.cost
        sanitized_feature.bonus = feature.bonus
        sanitized_feature.hidden = feature.hidden
        sanitized_feature.bought = feature.bought
        table.insert(sanitized_state.features, sanitized_feature)
    end
    return sanitized_state
end

function saveGame()
    local file = love.filesystem.newFile("savegame.json")
    file:open("w")
    local json_data = json.encode(sanitizedGameState())
    file:write(json_data)
    file:close()
end
