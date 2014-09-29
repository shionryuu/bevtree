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

bevtree = require "bevtree"

local function test(a)
    print(a.desc)
    return bevtree.Finish
end

local BevTree = bevtree.BevNodeRandomSelector {
    desc = "root node",
    --    precondition = nil,
    nodes = {
        bevtree.BevNodeTerminal {
            desc = "node 1",
            onExecute = function(_, _)
                print("node 1")
                return bevtree.Finish
            end
        },
        bevtree.BevNodeTerminal {
            desc = "node 2",
            onExecute = function(_, _)
                print("node 2")
                return bevtree.Finish
            end
        },
        bevtree.BevNodeTerminal {
            desc = "node 3",
            onExecute = test
        },
    },
}

local bevInput = { desc = "bev input" }
local bevOutput = { desc = "bev onput" }

for _ = 1, 10 do
    if BevTree:evaluate(bevInput) then
        BevTree:tick(bevInput, bevOutput)
    end
end
