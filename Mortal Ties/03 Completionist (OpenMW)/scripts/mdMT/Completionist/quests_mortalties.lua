local self = require('openmw.self')

local mortalTiesQuests = {

	{
		id = "mdMT_MortalTies",
		name = "Mortal Ties",
		category = "Miscellaneous",
		subcategory = "Sadrith Mora",
		text = "Deliver a special potion to a customer with an interesting family history."
	},

}

local hasSent = false

return {
    engineHandlers = {
        onUpdate = function(dt)
           
            if not hasSent then
                print("[Completionist] Sending quest data...")
               
                self:sendEvent("Completionist_RegisterPack", mortalTiesQuests)
               
                print("[Completionist] Data sent successfully!")
                hasSent = true
            end
        end
    }
}