--
-- Description: Behaviour tree in lua.
-- Copyright (c) 2014 ShionRyuu (shionryuu@outlook.com). 
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--

local class = require "middleclass.middleclass"

-- execute state
local Executing = 0
local Finish = 1
local Transition = -1
-- node state
local NodeReady = 0
local NodeRunning = 1
local NodeFinish = 2
--
local InvalidIndex = -1
local InfiniteLoop = -1


--[[
--
 ]]

-- base condition class
local BevNodePrecondition = class('BevNodePrecondition')

function BevNodePrecondition:initialize()
end

function BevNodePrecondition:externalCondition(_) -- input
    return true
end

-- always true condition
local BevNodePreconditionTRUE = class('BevNodePreconditionTRUE', BevNodePrecondition)

function BevNodePreconditionTRUE:initialize()
    BevNodePrecondition.initialize(self)
end

function BevNodePreconditionTRUE:externalCondition(_) -- input
    return true
end


-- always false condition
local BevNodePreconditionFALSE = class('BevNodePreconditionFALSE', BevNodePrecondition)

function BevNodePreconditionFALSE:initialize()
    BevNodePrecondition.initialize(self)
end

function BevNodePreconditionFALSE:externalCondition(_) -- input
    return false
end


-- not condition
local BevNodePreconditionNOT = class('BevNodePreconditionNOT', BevNodePrecondition)

function BevNodePreconditionNOT:initialize(precondition)
    BevNodePrecondition.initialize(self)
    self.precondition = precondition
end

function BevNodePreconditionNOT:externalCondition(input)
    return not self.precondition:externalCondition(input)
end


-- and condition
local BevNodePreconditionAND = class('BevNodePreconditionAND', BevNodePrecondition)

function BevNodePreconditionAND:initialize(lPrecondition, rPrecondition)
    BevNodePrecondition.initialize(self)
    self.lPrecondition = lPrecondition
    self.rPrecondition = rPrecondition
end

function BevNodePreconditionAND:externalCondition(input)
    return self.lPrecondition:externalCondition(input) and
            self.rPrecondition:externalCondition(input)
end


-- or condition
local BevNodePreconditionOR = class('BevNodePreconditionOR', BevNodePrecondition)

function BevNodePreconditionOR:initialize(lPrecondition, rPrecondition)
    BevNodePrecondition.initialize(self)
    self.lPrecondition = lPrecondition
    self.rPrecondition = rPrecondition
end

function BevNodePreconditionOR:externalCondition(input)
    return self.lPrecondition:externalCondition(input) or
            self.rPrecondition:externalCondition(input)
end


-- all condition
local BevNodePreconditionALL = class('BevNodePreconditionALL', BevNodePrecondition)

function BevNodePreconditionALL:initialize(List)
    BevNodePrecondition.initialize(self)
    self.preconditionList = List
end

function BevNodePreconditionALL:externalCondition(input)
    for i = 1, #self.preconditionList do
        if #self.preconditionList[i]:externalCondition(input) == false then
            return false
        end
    end
    return true
end


-- any condition
local BevNodePreconditionANY = class('BevNodePreconditionANY', BevNodePrecondition)

function BevNodePreconditionANY:initialize(List)
    BevNodePrecondition.initialize(self)
    self.preconditionList = List
end

function BevNodePreconditionANY:externalCondition(input)
    for i = 1, #self.preconditionList do
        if #self.preconditionList[i]:externalCondition(input) == true then
            return true
        end
    end
    return false
end


-- any condition
local BevNodePreconditionRANDOM = class('BevNodePreconditionRANDOM', BevNodePrecondition)

function BevNodePreconditionRANDOM:initialize() -- randSeed ?
    BevNodePrecondition.initialize(self)
end

function BevNodePreconditionRANDOM:externalCondition(_) -- input
    return random(1, 2) == 1
end


--[[
--
 ]]

-- base node class
local BevNode = class('BevNode')

function BevNode:initialize(config)
    self.childNodeList = config.nodes or {}
    self.desc = config.desc or "BevNode"
    self.precondition = config.precondition or nil
    self.currentSelectIndex = InvalidIndex
    self.lastSelectIndex = InvalidIndex
    self.currentActiveNode = nil
    self.lastActiveNode = nil
end

function BevNode:evaluate(input)
    return (self.precondition == nil or self.precondition:externalCondition(input)) and self:doEvaluate(input)
end

function BevNode:doEvaluate(_) -- input
    return true
end

function BevNode:tick(input, output)
    self:doTick(input, output)
end

function BevNode:doTick(input, output)
    return Finish
end

function BevNode:transition(input)
    self:doTransition(input)
end

function BevNode:doTransition(_) -- input
end

function BevNode:checkIndex(index)
    return index and index >= 1 and index <= #self.childNodeList
end

-- add child node
function BevNode:addChild(childNode)
    self.childNodeList = self.childNodeList:insert(childNode)
end

function BevNode:setActiveNode(node)
    self.lastActiveNode = self.currentActiveNode
    self.currentActiveNode = node
end


-- priority selector(weight selector)
local BevNodePrioritySelector = class('BevNodePrioritySelector', BevNode)

function BevNodePrioritySelector:initialize(config)
    BevNode.initialize(self, config)
end

function BevNodePrioritySelector:doEvaluate(input)
    self.currentSelectIndex = InvalidIndex
    for i = 1, #self.childNodeList do
        if self.childNodeList[i]:evaluate(input) == true then
            self.currentSelectIndex = i
            return true
        end
    end
    return false
end

function BevNodePrioritySelector:doTick(input, output)
    if self:checkIndex(self.currentSelectIndex) and
            self:checkIndex(self.lastSelectIndex) and
            self.currentSelectIndex ~= self.lastSelectIndex then
        -- clear last
        self.lastSelectIndex = self.currentSelectIndex
    end
    if self:checkIndex(self.currentSelectIndex) and
            self.childNodeList[self.currentSelectIndex]:tick(input, output) == Finish then
        self.lastSelectIndex = InvalidIndex
    end
end

function BevNodePrioritySelector:doTransition(input)
    if self:checkIndex(self.lastSelectIndex) then
        self.childNodeList[self.lastSelectIndex]:transition(input)
    end
end


-- none priority selector
local BevNodeNonePrioritySelector = class('BevNodeNonePrioritySelector', BevNodePrioritySelector)

function BevNodeNonePrioritySelector:initialize(config)
    BevNodePrioritySelector.initialize(self, config)
end

function BevNodeNonePrioritySelector:doEvaluate(input)
    if self:checkIndex(self.currentSelectIndex) and
            self.childNodeList[self.currentSelectIndex]:tick(input, output) == Finish then
        return true
    end
    return BevNodePrioritySelector.evaluate(self, input)
end


-- random selector
local BevNodeRandomSelector = class('BevNodeRandomSelector', BevNodePrioritySelector)

function BevNodeRandomSelector:initialize(config)
    BevNode.initialize(self, config)
end

function BevNodeRandomSelector:doEvaluate(input)
    if #self.childNodeList >= 1 then
        local RandomIndex = math.random(1, #self.childNodeList)
        if self.childNodeList[RandomIndex]:evaluate(input) == true then
            self.currentSelectIndex = RandomIndex
            return true
        end
    end
    return false
end


-- sequence
local BevNodeSequence = class('BevNodeSequence', BevNode)

function BevNodeSequence:initialize(config)
    BevNode.initialize(self, config)
end

function BevNodeSequence:doEvaluate(input)
    local Index = self.currentSelectIndex
    if not self:checkIndex(self.currentSelectIndex) and self:checkIndex(1) then
        Index = 1
    end
    if self:checkIndex(Index) then
        return self.childNodeList[Index]:evaluate(input)
    end
    return false
end

function BevNodeSequence:doTick(input, output)
    if not self:checkIndex(self.currentSelectIndex) and self:checkIndex(1) then
        self.currentSelectIndex = 1
    end
    if self:checkIndex(self.currentSelectIndex) and
            self.childNodeList[self.currentSelectIndex]:tick(input, output) == Finish then
        self.currentSelectIndex = self.currentSelectIndex + 1
    end
end

function BevNodeSequence:doTransition(input)
    if self:checkIndex(self.currentSelectIndex) then
        self.childNodeList[self.currentSelectIndex]:transition(input)
    end
    self.currentSelectIndex = InvalidIndex
end


-- parallel
local BevNodeParallel = class('BevNodeParallel', BevNode)

function BevNodeParallel:initialize(config)
    BevNode.initialize(self, config)
end

function BevNodeParallel:doEvaluate(input)
    for i = 1, #self.childNodeList do
        if not self.childNodeList[i]:evaluate(input) then
            return false
        end
    end
    return true
end

function BevNodeParallel:doTick(input, output)
    for i = 1, #self.childNodeList do
        if not self.childNodeList[i]:tick(input, output) then
            return Executing
        end
    end
    return Finish
end

function BevNodeParallel:doTransition(input)
    for i = 1, #self.childNodeList do
        self.childNodeList[i]:transition(input)
    end
end


-- loop
local BevNodeLoop = class('BevNodeLoop', BevNode)

function BevNodeLoop:initialize(config)
    BevNode.initialize(self, config)
    self.loopCount = config.loopCount or InfiniteLoop
    self.currentCount = 0
end

function BevNodeLoop:doEvaluate(input)
    local checkLoop = self.loopCount ~= InfiniteLoop and
            self.currentCount > self.loopCount
    if not checkLoop then
        return false
    elseif self:checkIndex(1) then
        return self.childNodeList[1]:evaluate(input)
    else
        return false
    end
end

function BevNodeLoop:doTick(input, output)
    if self:checkIndex(1) and self.childNodeList[1]:tick(input, output) then
        self.currentCount = self.currentCount + 1
    end
    if self.loopCount ~= InfiniteLoop and
            self.currentCount > self.loopCount then
        return Finish
    else
        return Executing
    end
end

function BevNodeLoop:doTransition(input)
    if self:checkIndex(1) then
        self.childNodeList[1]:transition(input)
    end
    self.currentCount = 0
end


--
local BevNodeTerminal = class('BevNodeTerminal', BevNode)

function BevNodeTerminal:initialize(config)
    BevNode.initialize(self, config)
    self.onEnter = config.onEnter or nil
    self.onExecute = config.onExecute or nil -- self.update = nil
    self.onExit = config.onExit or nil
    self.needTransition = false
    self.status = NodeReady
end

function BevNodeTerminal:doTick(input, output)
    local bIsFinish = Finish

    if self.status == NodeReady then
        self:doEnter(input)
        self.needTransition = true
        self.status = NodeRunning
        self:setActiveNode(self)
    end

    if self.status == NodeRunning then
        self:setActiveNode(self)
        bIsFinish = self:doExecute(input, output)
        if bIsFinish == Finish or bIsFinish == Finish then
            self.status = NodeFinish
        end
    end

    if self.status == NodeFinish then
        if self.needTransition then
            self:doExit(input, bIsFinish)
        end
        self:setActiveNode(nil)
        self.status = NodeReady
        self.needTransition = false
    end

    return bIsFinish
end

function BevNodeTerminal:doTransition(input)
    if self.needTransition then
        self:doExit(input, Transition)
    end
    self:setActiveNode(nil)
    self.status = NodeReady
    self.needTransition = false
end

function BevNodeTerminal:doEnter(input)
    if type(self.onEnter) == "function" then
        self.onEnter(input)
    elseif self.onEnter ~= nil then
        pcall(self.onEnter, input, output)
    end
end

function BevNodeTerminal:doExecute(input, output)
    if type(self.onExecute) == "function" then
        return self.onExecute(input, output)
    elseif self.onEnter ~= nil then
        return pcall(self.onExecute, input, output)
    end
    return Finish
end

function BevNodeTerminal:doExit(input, output)
    if type(self.onExit) == "function" then
        self.onExit(input, output)
    elseif self.onEnter ~= nil then
        pcall(self.onExecute, input, output)
    end
end


--[[
--
 ]]

return {
    Executing = Executing,
    Finish = Finish,
    Transition = Transition,
    InvalidIndex = InvalidIndex,
    --
    NodeReady = NodeReady,
    NodeRunning = NodeRunning,
    NodeFinish = NodeFinish,
    --
    InvalidIndex = InvalidIndex,
    InfiniteLoop = InfiniteLoop,
    --
    BevNodePrecondition = BevNodePrecondition,
    BevNodePreconditionTRUE = BevNodePreconditionTRUE,
    BevNodePreconditionFALSE = BevNodePreconditionFALSE,
    BevNodePreconditionNOT = BevNodePreconditionNOT,
    BevNodePreconditionAND = BevNodePreconditionAND,
    BevNodePreconditionOR = BevNodePreconditionOR,
    BevNodePreconditionALL = BevNodePreconditionALL,
    BevNodePreconditionANY = BevNodePreconditionANY,
    BevNodePreconditionRANDOM = BevNodePreconditionRANDOM,
    --
    BevNode = BevNode,
    BevNodePrioritySelector = BevNodePrioritySelector,
    BevNodeNonePrioritySelector = BevNodeNonePrioritySelector,
    BevNodeRandomSelector = BevNodeRandomSelector,
    BevNodeParallel = BevNodeParallel,
    BevNodeSequence = BevNodeSequence,
    BevNodeLoop = BevNodeLoop,
    BevNodeTerminal = BevNodeTerminal,
}
