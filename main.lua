--[[
        Rope Simulation


        Ahmed Dawoud
    adawoud1000@hotmail.com
]]

require 'Utils'
Class = require "Class"
Vector = require "vector"

Point = Class {
    position = Vector(),
    prevPosition = Vector(),
    locked = false,
    init = function(self, position, locked)
        self.position = position
        self.prevPosition = self.position
        self.locked = locked or false
    end
}

Stick = Class {
    pointA,
    pointB,
    length,
    init = function(self, pointA, pointB, length)
        self.pointA = pointA
        self.pointB = pointB
        self.length = length or DistanceBetweenVectors(self.pointA.position, self.pointB.position)
    end
}

function love.load()
    love.window.setMode(1280, 720)

    love.graphics.setLineWidth(4)

    points = {}
    sticks = {}

    pointRadius = 2

    --[[
        Code used for making a rope
            ropeQuality = 50
            for i = 1, ropeQuality, 1 do
                points[i] = Point(Vector(100 + i * 10, 200), i == 1 or i == ropeQuality)
            end
            for i = 1, ropeQuality - 1, 1 do
                sticks[i] = Stick(points[i], points[i + 1])
                pointRadius = 10
            end
    ]]

    -- A temp line to hold the stick drawing.
    tempLine = nil

    -- Wheather the simulation is running or not.
    started = false

    -- Auto adding mode to automatically add points with stick with certain distance.
    autoAddingMode = false
    autoAdding = {
        distance = 40
    }

    gravity = 980
end

function love.update(dt)

    -- If drawing the stick with the mouse change the end point to the mouse position.
    if tempLine then
        if love.mouse.isDown(1) then
            tempLine.endPosition = Vector(love.mouse.getX(), love.mouse.getY())
        end
    end

    -- Enable "AutoAddingMode" by holding shift and control keys.
    autoAddingMode = love.keyboard.isDown('lctrl') and love.keyboard.isDown('lshift')

    --[[
        Auto Adding Mode
    ]]
    if autoAddingMode and autoAdding.started then
        -- Only add new points if the distance greater than the threshold.
        if DistanceBetweenVectors(Vector(love.mouse.getX(), love.mouse.getY()), autoAdding.position) >
            autoAdding.distance then
            -- Add the point to the mosue position.
            table.insert(points, Point(Vector(love.mouse.getX(), love.mouse.getY())))
            -- Add a stick between the last 2 points.
            -- The line starts with a point we don't have to worry about nil indexing.
            table.insert(sticks, Stick(points[#points], points[#points - 1]))
            -- Update the last point position.
            autoAdding.position = Vector(love.mouse.getX(), love.mouse.getY())
        end
    end

    if started then
        Simulate(dt)
    end
end

function love.draw()
    love.graphics.clear(40 / 255, 44 / 255, 52 / 255)

    -- Move the first point with the mosue if "F" is held down.
    if points[1] and love.keyboard.isDown("f") then
        points[1].position = Vector(love.mouse.getPosition())
    end

    --[[
        Draw the sticks.
    ]]
    rgb(255, 255, 255, 0.7)
    for _, stick in ipairs(sticks) do
        love.graphics.line(stick.pointA.position.x, stick.pointA.position.y, stick.pointB.position.x,
            stick.pointB.position.y)
    end

    -- if there's a temp line "while drawing a stick" draw it with less alpha value.
    if tempLine then
        rgb(80, 80, 80, 0.7)
        love.graphics.line(tempLine.startPos.x, tempLine.startPos.y, tempLine.endPosition.x, tempLine.endPosition.y)
    end

    --[[
        Drawing the points
    ]]
    for _, point in ipairs(points) do
        if point.locked then
            rgb(179, 56, 106)
        else
            rgb()
        end
        love.graphics.circle("fill", point.position.x, point.position.y, pointRadius)
    end

    love.graphics.print("FPS :" .. tostring(love.timer.getFPS()))
end

--[[
    Simulate the points with Verlet Integration
]]
function Simulate(dt)
    for _, point in ipairs(points) do
        if not point.locked then
            local positionBeforeUpdate = point.position
            point.position = 2 * point.position - point.prevPosition
            point.position = point.position + Vector(0, 1) * gravity * dt * dt
            point.prevPosition = positionBeforeUpdate
        end
    end
    for _ = 0, 100 do
        for _, stick in ipairs(sticks) do
            local stickCentre = (stick.pointA.position + stick.pointB.position) / 2
            local stickDir = (stick.pointA.position - stick.pointB.position):normalized()
            if DistanceBetweenVectors(stick.pointA.position, stick.pointB.position) > stick.length then
                if not stick.pointA.locked then
                    stick.pointA.position = stickCentre + stickDir * stick.length / 2
                end
                if not stick.pointB.locked then
                    stick.pointB.position = stickCentre - stickDir * stick.length / 2
                end
            end
        end
    end
end

function love.mousepressed(x, y, button, istouch, presses)

    if button == 1 then
        if autoAddingMode then
            autoAdding.position = Vector(x, y)
            autoAdding.started = true
            -- Start the "Auto Adding Mode" with a point. 
            table.insert(points, Point(Vector(x, y)))
        else
            -- If clicked on a point start creating a new stick.
            for i, point in ipairs(points) do
                if point.position.x - pointRadius * 1.5 < x and point.position.x + pointRadius * 1.5 > x and
                    point.position.y - pointRadius * 1.5 < y and point.position.y + pointRadius * 1.5 > y then
                    tempLine = {}
                    tempLine.startPos = Vector(point.position.x, point.position.y)
                    tempLine.startingPointIndex = i
                    return
                end
            end
            table.insert(points, Point(Vector(x, y)))
        end
    -- Right Clicked to touggle the locked bool of the point.
    elseif button == 2 then
        for i, point in ipairs(points) do
            if point.position.x - pointRadius * 1.5 < x and point.position.x + pointRadius * 1.5 > x and
                point.position.y - pointRadius * 1.5 < y and point.position.y + pointRadius * 1.5 > y then
                if point.locked then
                    point.locked = false
                else
                    point.locked = true
                end
                break
            end
        end
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    movedPoint = nil
    autoAdding.started = false
    -- If dawing a staic finish it.
    if tempLine then
        for i, point in ipairs(points) do
            if tempLine.startingPointIndex ~= i and point.position.x - pointRadius * 1.5 < x and point.position.x +
                pointRadius * 1.5 > x and point.position.y - pointRadius * 1.5 < y and point.position.y + pointRadius *
                1.5 > y then
                table.insert(sticks, Stick(points[tempLine.startingPointIndex], points[i], DistanceBetweenVectors(
                    points[tempLine.startingPointIndex].position, points[i].position)))
            end
        end
        tempLine = nil
    end
end

function love.keyreleased(key, scancode)
    if key == "lctrl" or key == "rctrl" then
        tempLine = nil
        autoAddingMode = false
    elseif key == "lshift" then
        autoAddingMode = false
    elseif key == "space" then
        started = not started
    elseif key == "c" then
        points = {}
        sticks = {}
        started = false
    elseif key == "x" then
        points[#points].locked = not points[#points].locked
    end
end
