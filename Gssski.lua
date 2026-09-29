-- ══════════════════════════════════════════════════════════════
-- UNIVERSAL FRAMEWORK v5.1 — FULL BUILD
-- 1850+ keywords · 16 strategies · event-specific blocks
-- Codex Android safe · CoreGui fallback · viewport-locked UI
-- Log buffer · COPY button · print/warn capture
-- ══════════════════════════════════════════════════════════════
-- Usage: load in Codex → press SCAN → review → DRY → LIVE
-- ⚠️ Roblox TOS applies. Alt account. Private server preferred.
-- This is a remote SCANNER. It does not grant gamepasses.
-- ══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local MSS = game:GetService("MarketplaceService")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

-- ══════════════════════════════════════════════════════════════
-- 1 · KEYWORD BANK
-- ══════════════════════════════════════════════════════════════
local MEGA = {
unlock = {
"unlock","Unlock","UNLOCK","unlocked","Unlocked","unlocking","unlocker","lock","Lock","locked","unlock_","_unlock",
"unlockpet","unlockPet","unlock_pet","unlockpets","unlockPets","unlockpetgamepass","unlockPetGamepass","unlockpetpass",
"unlockshard","unlockShard","unlock_shard","unlockshards","unlockShards","unlockdab","unlockDab","unlock_dab","unlockdabs",
"unlockdabsword","unlockDabSword","unlock_dab_sword","unlockdabswordgamepass","unlockDabSwordGamepass",
"unlocksword","unlockSword","unlock_sword","unlockweapon","unlockWeapon","unlockweapongamepass","unlockWeaponGamepass",
"unlockgamepass","unlockGamepass","unlock_gamepass","unlockgamepasses","unlockpass","unlockPass","unlock_pass","unlockpasses",
"unlockitem","unlockItem","unlockitems","unlockItems","unlocktool","unlockTool","unlocktools","unlockTools",
"unlockgun","unlockGun","unlockguns","unlockGuns","unlockarmor","unlockArmor","unlockarmors","unlockArmors","unlockarmour",
"unlockskin","unlockSkin","unlockskins","unlockSkins","unlockoutfit","unlockOutfit","unlockoutfits","unlockOutfits",
"unlockchar","unlockChar","unlockcharacter","unlockCharacter","unlockcharacters","unlockCharacters","unlockhero","unlockHero",
"unlockheroes","unlockHeroes","unlockunit","unlockUnit","unlockunits","unlockfighter","unlockFighter",
"unlockmount","unlockMount","unlockmounts","unlockMounts","unlockvehicle","unlockVehicle","unlockvehicles","unlockVehicles",
"unlockcar","unlockCar","unlockcars","unlockCars","unlockbike","unlockBike","unlockbikes","unlockBikes",
"unlockride","unlockRide","unlockrides","unlockRides","unlockability","unlockAbility","unlockabilities","unlockAbilities",
"unlockskill","unlockSkill","unlockskills","unlockSkills","unlockpower","unlockPower","unlockpowers","unlockPowers",
"unlockupgrade","unlockUpgrade","unlockupgrades","unlockUpgrades","unlocklevel","unlockLevel","unlocklevels","unlockLevels",
"unlockarea","unlockArea","unlockareas","unlockAreas","unlockmap","unlockMap","unlockmaps","unlockMaps",
"unlockzone","unlockZone","unlockzones","unlockZones","unlockworld","unlockWorld","unlockworlds","unlockWorlds",
"unlockdoor","unlockDoor","unlockdoors","unlockDoors","unlockchest","unlockChest","unlockchests","unlockChests",
"unlockcrate","unlockCrate","unlockcrates","unlockCrates","unlockbox","unlockBox","unlockboxes","unlockBoxes",
"unlockegg","unlockEgg","unlockeggs","unlockEggs","unlockbundle","unlockBundle","unlockbundles","unlockBundles",
"unlockpack","unlockPack","unlockpacks","unlockPacks","unlockdiamond","unlockDiamond","unlockdiamonds","unlockDiamonds",
"unlockgem","unlockGem","unlockgems","unlockGems","unlockcoin","unlockCoin","unlockcoins","unlockCoins",
"unlockcash","unlockCash","unlockcashs","unlockCashs","unlockgold","unlockGold","unlockgolds","unlockGolds",
"unlocktoken","unlockToken","unlocktokens","unlockTokens","unlockcrystal","unlockCrystal","unlockcrystals","unlockCrystals",
"unlockstar","unlockStar","unlockstars","unlockStars","unlockkey","unlockKey","unlockkeys","unlockKeys",
"unlockticket","unlockTicket","unlocktickets","unlockTickets","unlockvip","unlockVIP","unlockVip","unlockvips",
"unlockpremium","unlockPremium","unlockpremiums","unlockpro","unlockPro","unlockplus","unlockPlus",
"unlockelite","unlockElite","unlockmember","unlockMember","unlockfeature","unlockFeature","unlockfeatures","unlockFeatures",
"unlockperk","unlockPerk","unlockperks","unlockPerks","unlockbuff","unlockBuff","unlockbuffs","unlockBuffs",
"unlockboost","unlockBoost","unlockboosts","unlockBoosts","unlockemote","unlockEmote","unlockemotes","unlockEmotes",
"unlockanimation","unlockAnimation","unlockanimations","unlockAnimations","unlockeffect","unlockEffect","unlockeffects","unlockEffects",
"unlocktrail","unlockTrail","unlocktrails","unlockTrails","unlockaura","unlockAura","unlockauras","unlockAuras",
"unlockbadge","unlockBadge","unlockbadges","unlockBadges","unlocktitle","unlockTitle","unlocktitles","unlockTitles",
"unlockname","unlockName","unlocknames","unlockNames","unlocktag","unlockTag","unlocktags","unlockTags",
"unlockcolor","unlockColor","unlockcolors","unlockColors","unlocktheme","unlockTheme","unlockthemes","unlockThemes",
"unlockbg","unlockBG","unlockbackground","unlockBackground","unlockmusic","unlockMusic","unlockmusics","unlockMusics",
"unlockvoice","unlockVoice","unlockvoices","unlockVoices",
"petunlock","petUnlock","pet_unlock","petsunlock","petgamepassunlock","petpassunlock",
"shardunlock","dabunlock","dabswordunlock","swordunlock","gamepassunlock","passunlock",
"itemunlock","toolunlock","gununlock","weaponunlock","armorunlock","skinunlock","outfitunlock",
"charunlock","herounlock","unitunlock","mountunlock","vehicleunlock","carunlock","bikeunlock","rideunlock",
"abilityunlock","skillunlock","powerunlock","upgradeunlock","levelunlock","areaunlock","mapunlock","zoneunlock",
"worldunlock","doorunlock","chestunlock","crateunlock","boxunlock","eggunlock","bundleunlock","packunlock",
"vipunlock","premiumunlock","prounlock","featureunlock","perkunlock","boostunlock",
"emoteunlock","trailunlock","auraunlock","badgeunlock","titleunlock",
"petunlockgamepass","petgamepassunlock","shardunlockgamepass","shardgamepassunlock",
"dabunlockgamepass","dabswordunlockgamepass","swordunlockgamepass","swordgamepassunlock",
"gamepassunlockpet","gamepassunlockshard","gamepassunlocksword","gamepassunlockdab","gamepassunlockdabsword",
},

petunlock = {
"petunlock","petUnlock","pet_unlock","petunlockPet","petsunlock","petsUnlock","petsUnlockAll",
"petunlockall","petUnlockAll","pet_unlock_all","petsunlockall","unlockallpets","unlockAllPets","unlockallpet",
"unlockeverypet","unlockEveryPet","petunlockgamepass","petUnlockGamepass","petgamepassunlock","petGamepassUnlock",
"petunlockpass","petpassunlock","petunlockvip","petunlockpremium",
"petunlocklegendary","petunlockmythical","petunlocksecret","petunlockrare","petunlockepic",
"petunlockcommon","petunlockexclusive","petunlocklimited","petunlockevent","petunlockfree",
"hatchunlock","hatchUnlock","hatchallpets","hatchAllPets","hatchall","hatchAll",
"unlockall","unlockAll","unlockeverything","unlockEverything","unlockevery","unlockEvery",
"unlockfull","unlockFull","unlockcomplete","unlockComplete","unlockmax","unlockMax","unlockinfinite","unlockInfinite",
"unlocklegendary","unlockLegendary","unlockmythical","unlockMythical","unlocksecret","unlockSecret",
"unlockrare","unlockRare","unlockepic","unlockEpic","unlockexclusive","unlockExclusive",
"unlocklimited","unlockLimited","unlockevent","unlockEvent","unlockfree","unlockFree",
"unlockreward","unlockReward","unlockprize","unlockPrize","unlocktreasure","unlockTreasure","unlockloot","unlockLoot",
"unlockallpasses","unlockAllPasses","unlockallgamepasses","unlockAllGamepasses","unlockallvip","unlockAllVip",
"unlockpremiumpets","unlockvipzone","unlockmembership",
},

gamepass = {
"gamepass","game_pass","gamePass","GamePass","GAMEPASS","gamepasses","pass","Pass","PASS","passes",
"passid","passId","PassId","passID","pass_id","grantpass","grantPass","grant_pass","givepass",
"ownpass","ownsPass","haspass","hasPass","checkpass","checkPass","isowned","isOwned","is_owned","owns","owned","owner","ownership",
"verifypass","verifyPass","validatePass","passcheck","pass_check",
"product","devproduct","devProduct","developerproduct","developer_product","productid","productId","productID","product_id","productname",
"purchase","Purchase","purchased","purchases","purchasePass","purchasepass","buy","Buy","buying","bought","boughtpass","buyPass","buypass",
"shop","Shop","store","Store","market","Market","marketplace","checkout","order","Order","transaction","tx","receipt","payment","pay","paid",
"premium","Premium","vip","VIP","Vip","membership","member","subscriber","subscription","elite","pro","Pro","plus","Platinum","Gold","tier","Tier","rank","Rank",
"redeem","Redeem","redeemed","redeemCode","code","Code","promo","Promo","coupon","Coupon","voucher","Voucher","giftcode","giftCard","giftcard",
"activate","Activate","activation","activateCode","active","grant","Grant","granted","granting","give","Give","giving","given",
"award","Award","awarded","assign","Assign","provide","Provide","deliver","Deliver","apply","Apply","applied",
"register","Register","enroll","Enroll","subscribe","Subscribe","entitle","Entitle","entitlement","ownsGamepass","grantGamepass",
},

currency = {
"coin","coins","Coin","Coins","COIN","cash","Cash","CASH","money","Money","MONEY",
"currency","Currency","CURRENCY","fund","funds","balance","Balance","BALANCE","wallet","Wallet",
"account","Account","vault","Vault","bank","Bank","gem","gems","Gem","Gems","GEM",
"diamond","diamonds","Diamond","Diamonds","DIAMOND","ruby","rubies","sapphire","emerald","crystal","crystals",
"token","tokens","Token","Tokens","TOKEN","credit","credits","Credit","Credits","buck","bucks",
"point","points","Point","Points","pts","crown","crowns","star","stars","Star","essence","shard","shards",
"fragment","fragments","soul","souls","energy","Energy","gold","Gold","silver","Silver","bronze",
"yen","won","euro","usd","dollar","dollars","robux","Robux","tix","ticket","tickets","Ticket","Tickets",
"scrap","Scrap","junk","trash","relic","atom","atoms","matter","nucleus","nectar","honey","pollen","seed","seeds",
"snowflake","leaf","flower","petal","add","Add","ADD","adding","added","give","Give","GIVE",
"grant","Grant","GRANT","award","Award","reward","Reward","REWARD","gain","Gain","gained","earn","Earn","earned",
"collect","Collect","collected","claim","Claim","claimed","receive","Receive","received","obtain","Obtained",
"fetch","Fetch","gather","Gather","harvest","Harvest","mine","Mine","mined","mining","farm","Farm","farmed",
"drop","Drop","loot","Loot","prize","Prize","bonus","Bonus","BONUS","perk","Perk",
"increment","Increment","decrement","Decrement","increase","Increase","decrease","Decrease",
"modify","Modify","update","Update","set","Set","multiply","Multiply","divide","Divide",
"amount","Amount","quantity","Quantity","qty","Qty","value","Value","total","Total","sum","Sum",
"delta","Delta","diff","Diff","change","Change","multiplier","Multiplier","mult","Mult",
"x2","x3","x5","x10","x20","x50","x100","boost","Boost","double","Double","triple","Triple",
"daily","Daily","hourly","weekly","monthly","free","Free","gratis","trial","Trial",
"spin","Spin","wheel","Wheel","roll","Roll","lucky","Lucky","jackpot","Jackpot",
"case","Case","crate","Crate","chest","Chest","bag","Bag","box","Box","pack","Pack",
"key","Key","keys","Keys","gift","Gift","present","Present","tip","Tip","donate","Donate","donation",
"trade","Trade","trading","Trading","sell","Sell","sold","buy","Buy","bought","convert","Convert",
},

stats = {
"hp","HP","health","Health","HEALTH","damage","Damage","DMG","dmg","dps","power","Power","POWER",
"strength","Strength","defense","Defense","defence","armor","Armor","armour","speed","Speed","SPEED",
"velocity","Velocity","jump","Jump","jumppower","jumpPower","walkspeed","walkSpeed","attack","Attack","ATK","atk",
"sword","Sword","SWORD","weapon","Weapon","gun","Gun","tool","Tool","equip","Equip","level","Level","LEVEL",
"exp","Exp","EXP","xp","XP","experience","Experience","rank","Rank","tier","Tier","grade","Grade",
"point","Point","skill","Skill","ability","Ability","stat","Stat","attribute","Attribute","buff","Buff","debuff","Debuff",
"heal","Heal","healing","regen","Regen","shield","Shield","barrier","Barrier","mana","Mana","energy","Energy",
"stamina","Stamina","rage","Rage","fury","Fury","crit","Crit","critical","luck","Luck","charm","Charm",
"kill","Kill","kills","Kills","death","Death","deaths","wins","Wins","win","Win","loss","Loss","loses",
"match","Match","round","Round","wave","Wave","stage","Stage","floor","Floor","boss","Boss","mob","Mob","enemy","Enemy",
"spawn","Spawn","summon","Summon","respawn","Respawn","evolve","Evolve","evolution","Evolution",
"ascend","Ascend","ascension","Ascension","prestige","Prestige","rebirth","Rebirth","awaken","Awaken",
"upgrade","Upgrade","upgraded","fuse","Fuse","fusion","Fusion","combine","Combine","merge","Merge",
"craft","Craft","crafting","Crafting","enchant","Enchant","enchantment","Enchantment",
},

pet = {
"pet","Pet","PETS","pets","pet_hp","petHp","petHealth","pet_health","pet_damage","petDamage","petPower","pet_power",
"pet_sword","petSword","petAttack","pet_attack","pet_kill","petKill","petDeath","pet_death","pet_spawn","petSpawn",
"pet_summon","petSummon","pet_feed","petFeed","pet_train","petTrain","pet_level","petLevel","pet_evolve","petEvolve",
"pet_egg","petEgg","hatch","Hatch","hatching","Hatching","egg","Egg","Eggs","eggs","incubate","Incubate","incubator","Incubator",
"ownpet","ownPet","hasPet","pet_own","petOwn","petOwnership","pet_equip","equipPet","equip_pet","pet_sell","sellPet","pet_buy","buyPet",
"pet_give","givePet","petGrant","grantPet","pet_index","petIndex","pet_album","petAlbum","pet_collection","petCollection","pet_dex","petDex",
"companion","Companion","familiar","Familiar","minion","Minion","mount","Mount","ride","Ride","riding","Riding",
"character","Character","skin","Skin","outfit","Outfit",
},

admin = {
"admin","Admin","ADMIN","administrator","Administrator","mod","Mod","MOD","moderator","Moderator",
"staff","Staff","STAFF","owner","Owner","OWNER","dev","Dev","developer","Developer","founder","Founder","creator","Creator",
"ban","Ban","BAN","banned","Banned","banning","kick","Kick","KICK","kicked","Kicked","punish","Punish","punished","Punished",
"mute","Mute","MUTE","muted","Muted","warn","Warn","WARN","warning","Warning","report","Report","REPORT","reported",
"arrest","Arrest","jail","Jail","JAIL","prison","freeze","Freeze","frozen","Frozen","teleport","Teleport","tp","TP","warp","Warp",
"delete","Delete","DELETE","remove","Remove","removed","wipe","Wipe","WIPE","reset","Reset","RESET","shutdown","Shutdown","close","Close",
"explode","Explode","kill","Kill","KILL","killed","logout","Logout","disconnect","Disconnect",
"abuse","Abuse","cheat","Cheat","exploit","Exploit","anticheat","AntiCheat","anti_cheat",
"detection","Detection","detect","Detect","detected","anomaly","Anomaly","suspicious","Suspicious",
"violation","Violation","violate","Violate","flag","Flag","flagged","Flagged",
},

movement = {
"speed","Speed","SPEED","walkspeed","walkSpeed","jumppower","jumpPower","jump","Jump",
"fly","Fly","FLY","flight","Flight","teleport","Teleport","tween","Tween","warp",
"dash","Dash","sprint","Sprint","run","Run","noclip","NoClip","clip","Clip",
"gravity","Gravity","float","Float","hover","swim","Swim","climb","Climb","sit","Sit",
"ride","Ride","vehicle","Vehicle","car","Car","moving","Moving","move","Move","MOVED",
"position","Position","pos","Pos","coords","velocity","Velocity","direction","Direction",
"cframe","CFrame","anchor","Anchor","anchored","rootpart","RootPart","humanoidrootpart","HumanoidRootPart",
},

combat = {
"attack","Attack","ATK","hit","Hit","HIT","damage","Damage","DMG","dmg","hurt","Hurt",
"shoot","Shoot","fire","Fire","shot","Shot","swing","Swing","slash","Slash","stab","Stab",
"punch","Punch","kick","Kick","melee","Melee","range","Range","ranged","Ranged",
"aim","Aim","target","Target","lock","Lock","aimbot","Aimbot","silent","Silent",
"esp","ESP","wallhack","Wallhack","kill","Kill","KILL","slain","slay",
"die","Die","death","Death","dead","Dead","respawn","Respawn","spawn","Spawn",
"invincible","Invincible","godmode","GodMode","god","immune","Immune",
"shield","Shield","weapon","Weapon","gun","Gun","sword","Sword","knife","Knife",
"bow","Bow","arrow","Arrow","ammo","Ammo","bullet","Bullet","mag","Mag","reload","Reload","trigger",
},

quest = {
"quest","Quest","QUEST","quests","Quests","mission","Mission","MISSION","task","Task",
"objective","Objective","goal","Goal","complete","Complete","completed","Completed",
"finish","Finish","finished","Finished","accept","Accept","accepted","Accepted",
"abandon","Abandon","cancel","Cancel","progress","Progress","progressing",
"stage","Stage","phase","Phase","step","Step","chapter","Chapter","act","Act",
"daily","Daily","weekly","Weekly","monthly","event","Event","EVENT","seasonal","Seasonal",
"season","Season","battlepass","BattlePass","bp","BP","reward","Reward","REWARD",
"claim","Claim","CLAIM","claimed","Claimed","turnin","turnIn","turn_in","handin","handIn",
},

trade = {
"trade","Trade","TRADE","trading","Trading","swap","Swap","exchange","Exchange","exchanging",
"offer","Offer","offered","Offered","decline","Decline","declined","Decline",
"send","Send","sent","Sent","give","Give","receive","Receive","received","Receive",
"market","Market","marketplace","Marketplace","shop","Shop","store","Store","vendor","Vendor",
"price","Price","cost","Cost","value","Value","bid","Bid","auction","Auction","listing","Listing",
"dupe","Dupe","duplicate","Duplicate","giftwrap","giftWrap","gift_wrap","boxed","boxing",
},

housing = {
"house","House","home","Home","base","Base","plot","Plot","land","Land","property","Property",
"build","Build","building","Building","construct","furniture","Furniture","decor","Decor","decorate",
"place","Place","placed","Placed","put","Put","expand","Expand","extension","Extension",
"garden","Garden","farm","Farm","farmland","plant","Plant","planted","Planted",
"water","Water","watered","Watered","grow","Grow","harvest","Harvest","harvested","crop","Crop","crops","Crops",
},

social = {
"friend","Friend","friends","Friends","add_friend","follow","Follow","followed",
"like","Like","liked","favorite","Favorite","favourite","Favourite",
"vote","Vote","voted","voting","poll","Poll","survey","Survey",
"invite","Invite","invited","Invited","join","Join","joined","leave","Leave",
"party","Party","group","Group","team","Team","guild","Guild","clan","Clan","faction","Faction",
"chat","Chat","message","Message","pm","PM","emoji","Emoji","emote","Emote","dance","Dance",
},

rarity = {
"common","Common","uncommon","Uncommon","rare","Rare","RARE","veryrare","VeryRare","very_rare",
"superrare","SuperRare","epic","Epic","EPIC","legendary","Legendary","LEGENDARY",
"mythic","Mythic","mythical","Mythical","MYTHICAL","secret","Secret","SECRET",
"exclusive","Exclusive","EXCLUSIVE","limited","Limited","LIMITED","event","Event","EVENT",
"special","Special","unique","Unique","UNIQUE","ultra","Ultra","ULTRA","godly","Godly","god","God",
"divine","Divine","celestial","Celestial","cosmic","Cosmic","ancient","Ancient","primordial","Primordial",
"vintage","Vintage","collector","Collector","collection","Collection","fused","Fused","fusion","Fusion",
"rainbow","Rainbow","shiny","Shiny","golden","Golden","holographic","Holographic","neon","Neon","glitch","Glitch",
"tier","Tier","TIER","grade","Grade","rank","Rank",
},

action = {
"spawn","Spawn","SPAWN","despawn","Despawn","respawn","Respawn","summon","Summon","summoning","Summoning",
"create","Create","created","Creating","generate","Generate","produce","Produce","produced","build","Build","built",
"craft","Craft","crafted","forge","Forge","forged","smelt","Smelt","combine","Combine","combined","merge","Merge","merged",
"fuse","Fuse","fused","fusing","mix","Mix","mixed","split","Split","split_","divide","Divide","divided",
"duplicate","Duplicate","duped","Dupe","clone","Clone","cloned","copy","Copy","copied","paste","Paste","pasted",
"move","Move","moved","shift","Shift","shifting","rotate","Rotate","rotated","turn","Turn","turned",
"place","Place","placed","put","Put","set","Set","remove","Remove","removed","delete","Delete","deleted",
"clear","Clear","cleared","empty","Empty","emptied","fill","Fill","filled","refill","Refill","refilled",
"reset","Reset","reseted","swap","Swap","swapped","trade","Trade","traded",
"send","Send","sent","deliver","Deliver","delivered","receive","Receive","received","accept","Accept","accepted",
"reject","Reject","rejected","decline","Decline","declined","request","Request","requested","respond","Respond","responded",
"call","Call","called","invoke","Invoke","invoked","trigger","Trigger","triggered","fire","Fire","fired",
"activate","Activate","activated","deactivate","Deactivate","enable","Enable","enabled","disable","Disable","disabled",
"toggle","Toggle","toggled","switch","Switch","switched","start","Start","started","stop","Stop","stopped",
"begin","Begin","began","end","End","ended","pause","Pause","paused","resume","Resume","resumed",
"load","Load","loaded","save","Save","saved","sync","Sync","synced","refresh","Refresh","refreshed","reload","Reload","reloaded",
},

ui = {
"button","Button","btn","Btn","click","Click","clicked","press","Press","pressed",
"tap","Tap","tapped","touch","Touch","menu","Menu","MENU","panel","Panel","window","Window",
"popup","Popup","modal","Modal","dialog","Dialog","frame","Frame","container","Container",
"overlay","Overlay","tab","Tab","tabs","Tabs","page","Page","screen","Screen",
"gui","GUI","ui","UI","hud","HUD","interface","Interface","notify","Notify","notification","Notification",
"toast","Toast","alert","Alert","warning","Warning","confirm","Confirm","prompt","Prompt","input","Input",
"select","Select","selected","choose","Choose","choice","Choice","toggle","Toggle","checkbox","Checkbox","radio","Radio",
"slider","Slider","dropdown","Dropdown","list","List","scroll","Scroll","scrolled","drag","Drag","dragged",
"drop","Drop","dropped","hover","Hover","hovered","focus","Focus","focused","blur","Blur","blurred",
},

event = {
"event","Event","EVENT","events","Events","halloween","Halloween","HALLOWEEN",
"christmas","Christmas","xmas","Xmas","easter","Easter","thanksgiving","Thanksgiving",
"newyear","NewYear","new_year","summer","Summer","winter","Winter","spring","Spring","fall","Fall","autumn","Autumn",
"anniversary","Anniversary","birthday","Birthday","launch","Launch","release","Release","update","Update","patch","Patch",
"seasonal","Seasonal","season","Season","weekend","Weekend","weekly","Weekly","daily","Daily","hourly","Hourly",
"flash","Flash","limited","Limited","timed","Timed","expire","Expire","expired","Expired",
"active","Active","inactive","Inactive","ongoing","Ongoing","upcoming","Upcoming","ended","Ended","past","Past",
},

value = {
"value","Value","val","Val","id","ID","Id","_id","identifier","Identifier",
"key","Key","KEY","index","Index","idx","Idx","name","Name","NAME","label","Label","title","Title",
"type","Type","TYPE","kind","Kind","category","Category","data","Data","DATA","info","Info","INFO","payload","Payload",
"config","Config","configuration","Configuration","setting","Setting","settings","Settings",
"param","Param","parameter","Parameter","arg","Arg","argument","Argument","field","Field","property","Property","attribute","Attribute",
"amount","Amount","qty","Qty","quantity","Quantity","count","Count","num","Num","number","Number",
"total","Total","sum","Sum","avg","Avg","min","Min","max","Max","current","Current","curr","Curr",
"target","Target","goal","Goal","limit","Limit","cap","Cap","capacity","Capacity",
"rate","Rate","speed","Speed","time","Time","duration","Duration","delay","Delay","interval","Interval","frequency","Frequency",
"level","Level","lvl","Lvl","tier","Tier","rank","Rank","grade","Grade",
"state","State","status","Status","mode","Mode","phase","Phase","stage","Stage",
"start","Start","end","End","begin","Begin","finish","Finish",
"first","First","last","Last","next","Next","prev","Prev","primary","Primary","secondary","Secondary",
"main","Main","sub","Sub","aux","Aux",
},

exploit = {
"dupe","Dupe","duplicate","Duplicate","duped","Duplicated","clone","Clone","cloned","Cloned","copy","Copy","copied","Copied",
"negative","Negative","neg","Neg","minus","Minus","sub","Sub","underflow","Underflow","overflow","Overflow",
"bypass","Bypass","bypassed","Bypassed","skip","Skip","skipped","Skipped","skipping","Skipping",
"glitch","Glitch","glitched","Glitched","exploit","Exploit","exploited","Exploited",
"bug","Bug","bugged","Bugged","abuse","Abuse","abused","Abused","cheat","Cheat","cheated","Cheated","hack","Hack","hacked","Hacked",
"inject","Inject","injected","Injected","injection","Injection","patch","Patch","patched","Patched",
"fix","Fix","fixed","Fixed","broken","Broken","break","Break","spoof","Spoof","spoofed","Spoofed","fake","Fake","faked",
"noclip","Noclip","NoClip","ghost","Ghost","invisible","Invisible","godmode","GodMode","god_mode","immortal","Immortal",
},

premium = {
"vip","VIP","Vip","vip_","_vip","vip1","vip2","vip3","vipgold","vipGold","vip_plus","vipPlus",
"premium","Premium","PREM","prem","premium_","_premium","pro","Pro","PRO","pro_","_pro","proplus","ProPlus",
"elite","Elite","ELITE","elite_","_elite","plus","Plus","PLUS","plus_","_plus",
"gold","Gold","GOLD","gold_","_gold","golden","Golden","silver","Silver","SILVER","platinum","Platinum","PLATINUM",
"diamond","Diamond","DIAMOND","diamond_","_diamond","master","Master","MASTER","legend","Legend","LEGEND",
"champion","Champion","CHAMPION","hero","Hero","HERO","founder","Founder","FOUNDER",
"early","Early","EARLY","earlyaccess","EarlyAccess","early_access","beta","Beta","BETA","alpha","Alpha","ALPHA",
},

misc = {
"get","Get","GET","fetch","Fetch","set","Set","SET","update","Update",
"save","Save","load","Load","sync","Sync","init","Init","initialize","Initialize",
"start","Start","stop","Stop","end","End","begin","Begin","finish","Finish",
"request","Request","response","Response","query","Query","data","Data","info","Info",
"status","Status","state","State","verify","Verify","validate","Validate",
"check","Check","confirm","Confirm","send","Send","receive","Receive","post","Post",
"put","Put","patch","Patch","delete","Delete","grab","Grab",
},

-- ══════════════════════════════════════════════════════════════
-- WIKIRACE! / FALL EVENT — SPECIFIC
-- ══════════════════════════════════════════════════════════════
fallpass = {
"fall season pass","Fall Season Pass","FALL SEASON PASS","fallseasonpass",
"fall pass","Fall Pass","FALL PASS","fallpass","FallPass",
"wikirace pass","WikiRace Pass","wikiracepass",
"wikirace fall pass","WikiRace Fall Pass",
"wikirace fall season pass","WikiRace Fall Season Pass",
"wikirace! fall pass","WikiRace! Fall Pass",
"fall 2026","Fall 2026","fall2026","Fall2026",
"fall 2026 pass","Fall 2026 Pass",
"fall event pass","Fall Event Pass","falleventpass",
"fall event 2026","Fall Event 2026",
"premium pass","Premium Pass","premiumpass","PremiumPass",
"premium reward path","Premium Reward Path",
"reward path","Reward Path","rewardpath",
"premium path","Premium Path","premiumpath",
"wikirace","WikiRace","WIKIRACE","wiki","Wiki","WIKI",
"season","Season","SEASON","seasonal","Seasonal",
"fall","Fall","FALL","autumn","Autumn","AUTUMN",
"event","Event","EVENT","pass","Pass","PASS","passes","Passes",
"premium","Premium","PREM","prem",
"leaves","Leaves","leaf","Leaf","LEAF",
"applecider","AppleCider","apple_cider","Apple Cider","apple cider",
"pumpkinpie","PumpkinPie","pumpkin_pie","Pumpkin Pie","pumpkin pie",
"pumpkinlaptop","PumpkinLaptop","pumpkin_laptop","Pumpkin Laptop","pumpkin laptop",
"autumnoverlook","AutumnOverlook","autumn_overlook","Autumn Overlook","autumn overlook",
"cosmetic","Cosmetic","cosmetics","Cosmetics",
"reward","Reward","rewards","Rewards","instantreward","InstantReward","instant_reward",
"task","Task","tasks","Tasks","eventtask","EventTask","event_task",
"unlockfallpass","unlockFallPass","unlock_fall_pass",
"unlockwikiracepass","unlockWikiRacePass",
"unlockpremiumpass","unlockPremiumPass",
"unlockseasonpass","unlockSeasonPass","unlock_season_pass",
"unlockeventpass","unlockEventPass","unlock_event_pass",
"grantfallpass","grantFallPass","grantseasonpass","grantSeasonPass",
"claimfallpass","claimFallPass","claimseasonpass","claimSeasonPass",
"buyfallpass","buyFallPass","buypremiumpass","buyPremiumPass",
"redeemfallpass","redeemFallPass","redeemseasonpass","redeemSeasonPass",
"ownfallpass","ownFallPass","hasfallpass","hasFallPass",
"checkfallpass","checkFallPass","verifyfallpass","verifyFallPass",
"collectleaf","collectLeaf","collectleaves","collectLeaves",
"claimreward","claimReward","claimrewards","claimRewards",
"claimtask","claimTask","claimtasks","claimTasks",
"completetask","completeTask","completetasks","completeTasks",
"eventreward","EventReward","event_task_reward","eventTaskReward",
},

-- ══════════════════════════════════════════════════════════════
-- PUMPKIN / FALL COSMETICS
-- ══════════════════════════════════════════════════════════════
pumpkin = {
"pumpkin","Pumpkin","PUMPKIN","pumpkins","Pumpkins","pumpkin_","_pumpkin",
"pumpkinlaptop","PumpkinLaptop","pumpkin_laptop","Pumpkin Laptop","pumpkin laptop",
"pumpkinpass","PumpkinPass","pumpkin_pass",
"pumpkinhead","PumpkinHead","pumpkin_head","Pumpkin Head",
"pumpkinhat","PumpkinHat","pumpkin_hat","Pumpkin Hat",
"pumpkinmask","PumpkinMask","pumpkin_mask","Pumpkin Mask",
"pumpkincar","PumpkinCar","pumpkin_car","Pumpkin Car",
"pumpkinpet","PumpkinPet","pumpkin_pet","Pumpkin Pet",
"pumpkinhouse","PumpkinHouse","pumpkin_house",
"pumpkinlantern","PumpkinLantern","pumpkin_lantern","Pumpkin Lantern",
"pumpkincandle","PumpkinCandle","pumpkin_candle",
"pumpkinpie","PumpkinPie","pumpkin_pie","Pumpkin Pie","pumpkin pie",
"pumpkinspice","PumpkinSpice","pumpkin_spice","Pumpkin Spice",
"pumpkinpatch","PumpkinPatch","pumpkin_patch","Pumpkin Patch",
"pumpkinseed","PumpkinSeed","pumpkin_seed","Pumpkin Seed",
"ฟักทอง","ฟักทองน้อย","ฟักทองใหญ่","หัวฟักทอง",
"ฟักทองแล็ปท็อป","แล็ปท็อปฟักทอง",
"พัมพ์กิน","พัมคิน","พัมกิน",
"jackolantern","JackOLantern","jack_o_lantern","Jack O Lantern","jack-o-lantern",
"jacko","JackO","jack_o","jack-o",
"gourd","Gourd","gourds","Gourds",
"carve","Carve","carved","Carving","carving",
"halloween","Halloween","HALLOWEEN","spooky","Spooky","spook","Spook",
"candy","Candy","candies","Candies","trick","Trick","treat","Treat","trickortreat",
"cobweb","Cobweb","web","Web","spider","Spider","bat","Bat","ghost","Ghost","witch","Witch",
"scarecrow","Scarecrow","hay","Hay","haystack","Haystack",
"corn","Corn","maize","Maize","harvest","Harvest","harvested",
"acorn","Acorn","acorns","Acorns","maple","Maple","leafpile","LeafPile","leaf_pile",
"laptop","Laptop","LAPTOP","lap","Lap","notebook","Notebook",
"pumpkinlaptopcosmetic","PumpkinLaptopCosmetic",
"pumpkinlaptopitem","PumpkinLaptopItem",
"pumpkinlaptoptool","PumpkinLaptopTool",
"laptoppumpkin","LaptopPumpkin","laptop_pumpkin",
},

-- ══════════════════════════════════════════════════════════════
-- UNLOCK PUMPKIN — REMOTE NAME VARIANTS
-- ══════════════════════════════════════════════════════════════
unlockpumpkin = {
"unlockPumpkin","UnlockPumpkin","UNLOCKPUMPKIN",
"unlockpumpkin","unlock_pumpkin","unlock-pumpkin",
"pumpkinUnlock","PumpkinUnlock","PumpkinUnlockRemote",
"pumpkinunlock","pumpkin_unlock",
"unlockPumpkinCosmetic","unlockPumpkinItem","unlockPumpkinTool",
"unlockPumpkinLaptop","unlockPumpkinLaptopCosmetic","unlockPumpkinLaptopItem",
"unlockPumpkinHat","unlockPumpkinPet","unlockPumpkinSkin",
"pumpkinUnlockCosmetic","pumpkinUnlockItem","pumpkinUnlockTool",
"eventUnlockPumpkin","fallUnlockPumpkin","passUnlockPumpkin",
"fallEventUnlockPumpkin","wikiRaceUnlockPumpkin",
"unlockPumpkinFall","unlockPumpkinEvent","unlockPumpkinPass",
"claimPumpkin","ClaimPumpkin","claimpumpkin","claim_pumpkin",
"grantPumpkin","GrantPumpkin","grantpumpkin","grant_pumpkin",
"getPumpkin","GetPumpkin","getpumpkin","get_pumpkin",
"givePumpkin","GivePumpkin","givepumpkin","give_pumpkin",
"redeemPumpkin","RedeemPumpkin","redeempumpkin","redeem_pumpkin",
"buyPumpkin","BuyPumpkin","buypumpkin","buy_pumpkin",
"purchasePumpkin","PurchasePumpkin","purchasepumpkin",
"earnPumpkin","EarnPumpkin","earnpumpkin","earn_pumpkin",
"receivePumpkin","ReceivePumpkin","receivepumpkin",
"openPumpkin","OpenPumpkin","openpumpkin","open_pumpkin",
"activatePumpkin","ActivatePumpkin","activatepumpkin",
"unlockFaktong","unlockfaktong","unlock_faktong",
"faktongUnlock","faktongunlock",
"pumpkinGrant","pumpkinClaim","pumpkinRedeem","pumpkinBuy",
"pumpkinPurchase","pumpkinGet","pumpkinGive","pumpkinEarn",
"unlockPumpkinReward","unlockPumpkinPrize","unlockPumpkinBonus",
"claimPumpkinReward","claimPumpkinPrize","claimPumpkinBonus",
"grantPumpkinReward","grantPumpkinPrize","grantPumpkinBonus",
"unlockLaptop","UnlockLaptop","unlocklaptop","unlock_laptop",
"unlockPumpkinLaptopRemote","unlockPumpkinLaptopEvent",
"pumpkinLaptopUnlock","pumpkinLaptopGrant","pumpkinLaptopClaim",
},
}

-- count
local TOTAL_KW = 0
for _ , kws in pairs(MEGA) do TOTAL_KW = TOTAL_KW + #kws end

-- ══════════════════════════════════════════════════════════════
-- 2 · BLACKLIST
-- ══════════════════════════════════════════════════════════════
local BL = {"ban","kick","punish","admin","delete","wipe","shutdown","report","arrest","jail","explode","freeze","logout","mute","reset","destroy","abuse","anticheat","anomaly"}
local function isBL(name)
    local n = (name or ""):lower()
    for _, p in ipairs(BL) do if n:find(p,1,true) then return true, p end end
    return false, nil
end

-- ══════════════════════════════════════════════════════════════
-- 3 · TOKEN SPLITTER + COMPOUND MATCHER
-- ══════════════════════════════════════════════════════════════
local function tokenize(name)
    local tokens = {}
    for part in name:gmatch("[^_%-%.%s]+") do
        local buf = ""
        for i = 1, #part do
            local c = part:sub(i,i)
            if c:match("[A-Z]") and buf ~= "" then
                tokens[#tokens+1] = buf:lower()
                buf = c
            else
                buf = buf .. c
            end
        end
        if buf ~= "" then tokens[#tokens+1] = buf:lower() end
    end
    return tokens
end

local VERBS = {unlock=1,grant=1,give=1,add=1,set=1,get=1,check=1,verify=1,buy=1,purchase=1,redeem=1,claim=1,collect=1,earn=1,receive=1,obtain=1,activate=1,enable=1,use=1,spawn=1,equip=1,apply=1,send=1,request=1,fetch=1,load=1,save=1,update=1,modify=1,change=1,open=1,consume=1,enablepass=1}
local NOUNS = {pet=1,pets=1,shard=1,shards=1,dab=1,dabs=1,sword=1,swords=1,weapon=1,weapons=1,gun=1,guns=1,item=1,items=1,tool=1,tools=1,skin=1,skins=1,outfit=1,outfits=1,char=1,character=1,hero=1,heroes=1,unit=1,units=1,mount=1,mounts=1,vehicle=1,vehicles=1,car=1,cars=1,ability=1,abilities=1,skill=1,skills=1,power=1,powers=1,upgrade=1,upgrades=1,level=1,levels=1,area=1,areas=1,map=1,maps=1,zone=1,zones=1,world=1,worlds=1,door=1,doors=1,chest=1,chests=1,crate=1,crates=1,box=1,boxes=1,egg=1,eggs=1,bundle=1,bundles=1,pack=1,packs=1,coin=1,coins=1,cash=1,gem=1,gems=1,diamond=1,diamonds=1,gold=1,token=1,tokens=1,crystal=1,crystals=1,star=1,stars=1,key=1,keys=1,ticket=1,tickets=1,vip=1,premium=1,pro=1,elite=1,member=1,feature=1,features=1,perk=1,perks=1,buff=1,buffs=1,boost=1,boosts=1,emote=1,emotes=1,trail=1,trails=1,aura=1,auras=1,badge=1,badges=1,title=1,titles=1,gamepass=1,pass=1,passes=1,reward=1,rewards=1,prize=1,bonus=1,gift=1,loot=1,treasure=1,all=1,everything=1,every=1,full=1,complete=1,max=1,infinite=1,legendary=1,mythical=1,secret=1,rare=1,epic=1,exclusive=1,limited=1,event=1,free=1,pumpkin=1,laptop=1,fall=1,wikirace=1,leaf=1,leaves=1}

local function matchCompound(name)
    local tokens = tokenize(name)
    if #tokens < 2 then return 0, {} end

    local verbIdx, nounIdx = {}, {}
    for i, t in ipairs(tokens) do
        if VERBS[t] then verbIdx[#verbIdx+1] = i end
        if NOUNS[t] then nounIdx[#nounIdx+1] = i end
    end

    local hits, score = {}, 0

    if #verbIdx >= 1 and #nounIdx >= 2 then
        score = 150
        hits[#hits+1] = "C3:verb+2nouns"
    elseif #verbIdx >= 1 and #nounIdx >= 1 then
        score = 80
        hits[#hits+1] = "C2:verb+noun"
    end

    return score, hits
end

-- ══════════════════════════════════════════════════════════════
-- 4 · LOG BUFFER (before strategies so they can use it)
-- ══════════════════════════════════════════════════════════════
local LOG_LINES = {}

local function logPush(t)
    local ts
    local okDate = pcall(function() ts = os.date("%H:%M:%S") end)
    if not okDate then ts = string.format("%.1f", tick() % 10000) end
    LOG_LINES[#LOG_LINES+1] = ("[%s] %s"):format(ts, t)
    if #LOG_LINES > 800 then table.remove(LOG_LINES, 1) end
end

-- capture print/warn
local origPrint = print
local origWarn = warn
print = function(...)
    origPrint(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[#parts+1] = tostring(select(i, ...)) end
    logPush("PRINT " .. table.concat(parts, " "))
end
warn = function(...)
    origWarn(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[#parts+1] = tostring(select(i, ...)) end
    logPush("WARN  " .. table.concat(parts, " "))
end

-- ══════════════════════════════════════════════════════════════
-- 5 · STRATEGIES
-- ══════════════════════════════════════════════════════════════
local STRAT = {}

function STRAT.s1_direct(r)
    local n = (r.name or ""):lower()
    local score, hits = 0, {}
    for cat, kws in pairs(MEGA) do
        if cat == "admin" then goto cont end
        for _, kw in ipairs(kws) do
            if n:find(kw:lower(), 1, true) then
                score = score + 50
                hits[#hits+1] = "S1:"..kw
            end
        end
        ::cont::
    end
    return math.min(score, 300), hits
end

function STRAT.s2_path(r)
    local p = (r.path or ""):lower()
    local score, hits = 0, {}
    for cat, kws in pairs(MEGA) do
        if cat == "admin" then goto cont end
        for _, kw in ipairs(kws) do
            if p:find(kw:lower(), 1, true) then
                score = score + 25
                hits[#hits+1] = "S2:"..kw
            end
        end
        ::cont::
    end
    return math.min(score, 150), hits
end

function STRAT.s3_sibling(r)
    if typeof(r.obj) ~= "Instance" or not r.obj.Parent then return 0, {} end
    local score, hits = 0, {}
    for _, sib in ipairs(r.obj.Parent:GetChildren()) do
        if sib ~= r.obj and (sib:IsA("RemoteEvent") or sib:IsA("RemoteFunction")) then
            local n = sib.Name:lower()
            for cat, kws in pairs(MEGA) do
                if cat == "admin" then goto cont end
                for _, kw in ipairs(kws) do
                    if n:find(kw:lower(), 1, true) then
                        score = score + 15
                        hits[#hits+1] = "S3:"..kw
                        break
                    end
                end
                ::cont::
            end
        end
    end
    return math.min(score, 100), hits
end

function STRAT.s4_parent(r)
    if typeof(r.obj) ~= "Instance" or not r.obj.Parent then return 0, {} end
    local pn = (r.obj.Parent.Name or ""):lower()
    local score, hits = 0, {}
    for cat, kws in pairs(MEGA) do
        if cat == "admin" then goto cont end
        for _, kw in ipairs(kws) do
            if pn:find(kw:lower(), 1, true) then
                score = score + 30
                hits[#hits+1] = "S4:"..kw
            end
        end
        ::cont::
    end
    return math.min(score, 120), hits
end

function STRAT.s5_ngram(r)
    local n = (r.name or ""):lower()
    if #n < 3 then return 0, {} end
    local score, hits = 0, {}
    for i = 1, #n - 2 do
        local g = n:sub(i, i+2)
        for cat, kws in pairs(MEGA) do
            if cat == "admin" then goto cont end
            for _, kw in ipairs(kws) do
                if kw:lower():find(g, 1, true) then
                    score = score + 5
                    hits[#hits+1] = "S5:"..g
                    break
                end
            end
            ::cont::
        end
    end
    return math.min(score, 50), hits
end

function STRAT.s6_compound(r)
    return matchCompound(r.name or "")
end

function STRAT.s7_fingerprint(r)
    local cache = (getgenv and getgenv().SPY_CACHE) or {}
    local e = cache[r.path]
    if not e or not e.types then return 0, {} end
    local score, hits = 0, {}
    for i, t in ipairs(e.types) do
        if t == "num" then
            local v = e.values and e.values[i]
            if type(v) == "number" then
                if v > 1e6 then score = score + 40; hits[#hits+1] = "S7:bigNum"
                elseif v == 0 or v == 1 then score = score + 10; hits[#hits+1] = "S7:id"
                else score = score + 20; hits[#hits+1] = "S7:num" end
            end
        elseif t == "tbl" then score = score + 25; hits[#hits+1] = "S7:table"
        elseif t == "inst" then score = score + 15; hits[#hits+1] = "S7:inst" end
    end
    return math.min(score, 120), hits
end

function STRAT.s8_behavior(r)
    local map = (getgenv and getgenv().BEHAVIOR_MAP) or {}
    local e = map[r.path]
    if not e or not e.changes then return 0, {} end
    local score, hits = 0, {}
    for _, ch in ipairs(e.changes) do
        local n = (ch.name or ""):lower()
        for cat, kws in pairs(MEGA) do
            if cat == "admin" then goto cont end
            for _, kw in ipairs(kws) do
                if n:find(kw:lower(), 1, true) then
                    score = score + 80
                    hits[#hits+1] = "S8:"..kw
                    break
                end
            end
            ::cont::
        end
    end
    return math.min(score, 400), hits
end

function STRAT.s9_class(r)
    if r.type == "RemoteFunction" then return 25, {"S9:func"} end
    return 0, {}
end

function STRAT.s10_rate(r)
    local map = (getgenv and getgenv().RATE) or {}
    local rt = map[r.path] or 0
    if rt > 10 then return 35, {"S10:hot"} end
    if rt > 3 then return 15, {"S10:warm"} end
    return 0, {}
end

function STRAT.s11_dupe(r)
    if typeof(r.obj) ~= "Instance" or not r.obj.Parent then return 0, {} end
    local c = 0
    for _, sib in ipairs(r.obj.Parent:GetChildren()) do
        if sib ~= r.obj and sib.Name == r.obj.Name then c = c + 1 end
    end
    if c > 0 then return c * 10, {"S11:dupe"} end
    return 0, {}
end

function STRAT.s12_attr(r)
    if typeof(r.obj) ~= "Instance" then return 0, {} end
    local score, hits = 0, {}
    pcall(function()
        for attr, _ in pairs(r.obj:GetAttributes()) do
            local an = attr:lower()
            for cat, kws in pairs(MEGA) do
                if cat == "admin" then goto cont end
                for _, kw in ipairs(kws) do
                    if an:find(kw:lower(), 1, true) then
                        score = score + 30
                        hits[#hits+1] = "S12:"..kw
                    end
                end
                ::cont::
            end
        end
    end)
    return math.min(score, 100), hits
end

function STRAT.s13_fullPath(r)
    local p = (r.path or ""):lower()
    local score, hits = 0, {}
    for _, part in ipairs(tokenize(p)) do
        for cat, kws in pairs(MEGA) do
            if cat == "admin" then goto cont end
            for _, kw in ipairs(kws) do
                if kw:lower() == part then
                    score = score + 10
                    hits[#hits+1] = "S13:"..kw
                    break
                end
            end
            ::cont::
        end
    end
    return math.min(score, 100), hits
end

function STRAT.s14_recency(r)
    local map = (getgenv and getgenv().FIRST_SEEN) or {}
    local t = map[r.path]
    if t and tick() - t < 30 then return 20, {"S14:new"} end
    return 0, {}
end

function STRAT.s26_gamepassName(r)
    local n = (r.name or ""):lower()
    local hits = {}
    local score = 0
    local specific = {
        "fall season pass","fall pass","wikirace fall",
        "premium pass","reward path","season pass",
        "fall 2026","fall event",
        "pumpkin laptop","pumpkin laptop cosmetic","pumpkinlaptop",
        "unlockpumpkin","unlock pumpkin","unlock_pumpkin",
        "pumpkinunlock","pumpkin unlock","pumpkin_unlock",
    }
    for _, kw in ipairs(specific) do
        if n:find(kw, 1, true) then
            score = score + 200
            hits[#hits+1] = "S26:"..kw
        end
    end
    return score, hits
end

function STRAT.s27_marketplaceEnum(r)
    local n = (r.name or ""):lower()
    if n:find("passid", 1, true) or n:find("pass_id", 1, true)
       or n:find("gamepass", 1, true) or n:find("game_pass", 1, true) then
        return 60, {"S27:passid"}
    end
    return 0, {}
end

local STRATEGIES = {
    {name="direct",         fn=STRAT.s1_direct,         weight=1.0},
    {name="path",           fn=STRAT.s2_path,           weight=1.0},
    {name="sibling",        fn=STRAT.s3_sibling,        weight=1.0},
    {name="parent",         fn=STRAT.s4_parent,         weight=1.0},
    {name="ngram",          fn=STRAT.s5_ngram,          weight=1.0},
    {name="compound",       fn=STRAT.s6_compound,       weight=1.4},
    {name="fingerprint",    fn=STRAT.s7_fingerprint,    weight=1.0},
    {name="behavior",       fn=STRAT.s8_behavior,       weight=1.5},
    {name="class",          fn=STRAT.s9_class,          weight=1.0},
    {name="rate",           fn=STRAT.s10_rate,          weight=1.0},
    {name="dupe",           fn=STRAT.s11_dupe,          weight=1.0},
    {name="attr",           fn=STRAT.s12_attr,          weight=1.0},
    {name="fullPath",       fn=STRAT.s13_fullPath,      weight=1.0},
    {name="recency",        fn=STRAT.s14_recency,       weight=1.0},
    {name="gamepassName",   fn=STRAT.s26_gamepassName,  weight=2.0},
    {name="marketplaceEnum",fn=STRAT.s27_marketplaceEnum,weight=1.5},
}

local function fuse(r)
    local bl = isBL(r.name)
    if bl then return {total=-1, blocked=true} end

    local total = 0
    local active = 0
    local breakdown = {}
    local allHits = {}

    for _, s in ipairs(STRATEGIES) do
        local ok, score, hits = pcall(s.fn, r)
        if not ok then score, hits = 0, {} end
        score = (score or 0) * s.weight
        if score > 0 then active = active + 1 end
        total = total + score
        breakdown[s.name] = math.floor(score)
        for _, h in ipairs(hits or {}) do allHits[#allHits+1] = h end
    end

    if active >= 5 then total = total * 1.5 end
    if active >= 8 then total = total * 2.0 end

    return {
        total = math.floor(total),
        activeCount = active,
        breakdown = breakdown,
        hits = allHits,
        blocked = false,
    }
end

-- ══════════════════════════════════════════════════════════════
-- 6 · SCAN
-- ══════════════════════════════════════════════════════════════
local Scan = {remotes={}, stats={}}

local function collect()
    local seen = setmetatable({}, {__mode="k"})
    local out = {}

    local function add(obj)
        if seen[obj] then return end
        seen[obj] = true
        out[#out+1] = {
            obj = obj,
            path = obj:GetFullName(),
            name = obj.Name,
            type = obj.ClassName,
        }
    end

    local ok, list = pcall(function() return game:GetDescendants() end)
    if ok then
        local i = 0
        for _, obj in ipairs(list) do
            i = i + 1
            if i % 3000 == 0 then task.wait() end
            local c = obj.ClassName
            if c == "RemoteEvent" or c == "RemoteFunction" or c == "UnreliableRemoteEvent" then
                add(obj)
            end
        end
    end

    if type(getnilinstances) == "function" then
        pcall(function()
            local n = 0
            for _, obj in ipairs(getnilinstances()) do
                n = n + 1
                if n % 2000 == 0 then task.wait() end
                if typeof(obj) == "Instance" then
                    local c = obj.ClassName
                    if c == "RemoteEvent" or c == "RemoteFunction" then add(obj) end
                end
            end
        end)
    end

    if type(getgc) == "function" then
        pcall(function()
            local gc
            local ok2, g = pcall(getgc, false)
            if ok2 then gc = g else
                local ok3, g2 = pcall(getgc)
                if ok3 then gc = g2 end
            end
            if type(gc) == "table" then
                local n = 0
                for _, v in ipairs(gc) do
                    n = n + 1
                    if n % 3000 == 0 then task.wait() end
                    if n > 60000 then break end
                    if typeof(v) == "Instance" then
                        local c = v.ClassName
                        if c == "RemoteEvent" or c == "RemoteFunction" then add(v) end
                    end
                end
            end
        end)
    end

    return out
end

local function scan()
    print("═══ SCAN ═══")
    local list = collect()
    print(("  raw: %d"):format(#list))

    for _, r in ipairs(list) do
        local result = fuse(r)
        r.score = result.total
        r.detail = result
    end

    table.sort(list, function(a,b) return (a.score or 0) > (b.score or 0) end)
    Scan.remotes = list
    Scan.stats.total = #list
    print(("  scored: %d"):format(#list))
    for i, r in ipairs(list) do
        if i > 30 then break end
        if r.score and r.score > 50 and not r.detail.blocked then
            print(("  [%d] score=%d active=%d %s"):format(i, r.score, r.detail.activeCount, r.path))
        end
    end
end

-- ══════════════════════════════════════════════════════════════
-- 7 · ATTACK
-- ══════════════════════════════════════════════════════════════
local Attack = {fired=0, success=0, fail=0, detected=0, skipped=0}

local CONFIG = {
    DRY_RUN     = true,
    FIRE_DELAY  = 1.5,
    MAX_FIRES   = 100,
    MIN_SCORE   = 80,
    STOP_ON_DET = true,
}

local DETECT = {"banned","kicked","exploit","suspicious","detected","hack","cheat","unauthorized","invalid request","rate limit","spam","blocked","forbidden","insufficient permission"}

local function isDetect(s)
    if type(s) ~= "string" then return false end
    local l = s:lower()
    for _, p in ipairs(DETECT) do if l:find(p,1,true) then return true, p end end
    return false, nil
end

local function buildPayloads(r)
    local n = (r.name or ""):lower()
    local out = {}
    out[#out+1] = {}
    out[#out+1] = {0}
    out[#out+1] = {1}
    out[#out+1] = {111111111}
    out[#out+1] = {true}
    out[#out+1] = {"unlock"}
    out[#out+1] = {"grant"}
    out[#out+1] = {"unlock","pet"}
    out[#out+1] = {"unlock","sword"}
    out[#out+1] = {"unlock","gamepass"}
    out[#out+1] = {"grant","pass"}
    out[#out+1] = {{action="unlock"}}
    out[#out+1] = {{action="grant"}}
    if n:find("pumpkin",1,true) then
        out[#out+1] = {"unlock","pumpkin"}
        out[#out+1] = {"unlock","pumpkin","laptop"}
        out[#out+1] = {"pumpkin"}
        out[#out+1] = {"grant","pumpkin"}
        out[#out+1] = {"claim","pumpkin"}
    end
    if n:find("fall",1,true) or n:find("wikirace",1,true) then
        out[#out+1] = {"unlock","fall","pass"}
        out[#out+1] = {"grant","fall","pass"}
        out[#out+1] = {"claim","fall","pass"}
    end
    local tokens = tokenize(r.name or "")
    if #tokens >= 2 then out[#out+1] = tokens end
    if n:find("unlock",1,true) then
        out[#out+1] = {"unlock",0}
        out[#out+1] = {0,"unlock"}
    end
    return out
end

local function fireOne(r, payload)
    if isBL(r.name) then Attack.skipped = Attack.skipped + 1 return false, "bl" end
    if CONFIG.DRY_RUN then return true, "dry" end

    local ok, result = pcall(function()
        if r.type == "RemoteFunction" then
            return r.obj:InvokeServer(unpack(payload))
        else
            r.obj:FireServer(unpack(payload))
            return nil
        end
    end)

    if not ok then Attack.fail = Attack.fail + 1 return false, tostring(result) end
    if CONFIG.STOP_ON_DET then
        local det, pat = isDetect(result)
        if det then
            Attack.detected = Attack.detected + 1
            warn("[DETECT] "..pat..": "..tostring(result))
            CONFIG.DRY_RUN = true
            return false, "detect"
        end
    end
    Attack.success = Attack.success + 1
    return true, result
end

local function attack()
    print("═══ ATTACK ═══")
    if CONFIG.DRY_RUN then print("  [DRY RUN]") end

    local total = 0
    for _, r in ipairs(Scan.remotes) do
        if total >= CONFIG.MAX_FIRES then break end
        if Attack.detected > 0 then break end
        if not r.score or r.score < CONFIG.MIN_SCORE then goto cont end
        if r.detail and r.detail.blocked then goto cont end

        local payloads = buildPayloads(r)
        print(("  [%d] %s"):format(r.score, r.path))

        for _, p in ipairs(payloads) do
            if total >= CONFIG.MAX_FIRES then break end
            if Attack.detected > 0 then break end
            Attack.fired = Attack.fired + 1
            total = total + 1
            local ok, res = fireOne(r, p)
            task.wait(CONFIG.FIRE_DELAY)
        end
        ::cont::
    end

    print(("  fired=%d ok=%d fail=%d skip=%d det=%d"):format(
        Attack.fired, Attack.success, Attack.fail, Attack.skipped, Attack.detected))
end

-- ══════════════════════════════════════════════════════════════
-- 8 · VERIFY
-- ══════════════════════════════════════════════════════════════
local function verify()
    print("═══ VERIFY ═══")
    local ids = {}
    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("IntValue") or obj:IsA("NumberValue") then
                local v = obj.Value
                if type(v) == "number" and v > 1000000 and v < 99999999999 then
                    ids[#ids+1] = math.floor(v)
                end
            end
        end
    end)
    local seen = {}
    local uniq = {}
    for _, id in ipairs(ids) do
        if not seen[id] then seen[id] = true uniq[#uniq+1] = id end
    end
    print(("  discovered IDs: %d"):format(#uniq))
    for i = 1, math.min(#uniq, 15) do
        local id = uniq[i]
        local ok, owns = pcall(function() return MSS:UserOwnsGamePassAsync(LP.UserId, id) end)
        print(("  pass %d: %s"):format(id, ok and tostring(owns) or "err"))
        task.wait(0.3)
    end
end

-- ══════════════════════════════════════════════════════════════
-- 9 · GUI — Codex Android safe
-- ══════════════════════════════════════════════════════════════
local function resolveParent()
    if type(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and h then
            origPrint("[GUI] parent=gethui()")
            return h
        end
    end
    local cg = game:GetService("CoreGui")
    if cg then
        origPrint("[GUI] parent=CoreGui")
        return cg
    end
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if not pg then pg = LP:WaitForChild("PlayerGui", 10) end
    if pg then
        origPrint("[GUI] parent=PlayerGui")
        return pg
    end
    return nil
end

local parent = resolveParent()
if not parent then
    origWarn("[GUI] no parent — abort")
    return
end

local gui = Instance.new("ScreenGui")
gui.Name = "UniversalFW_"..tostring(math.random(1000,9999))
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = true
gui.Parent = parent

local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(400,700)
local W = math.min(440, math.max(340, vs.X - 24))
local H = math.min(400, math.max(320, vs.Y - 80))

local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, W, 0, H)
frame.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
frame.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Visible = true
frame.ZIndex = 2
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(180, 100, 255)
stroke.Thickness = 1
stroke.Transparency = 0.4
stroke.Parent = frame

-- drag
local dragging, dragStart, startPos = false, nil, nil
local titleBar = Instance.new("TextLabel")
titleBar.Size = UDim2.new(1, 0, 0, 60)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundTransparency = 1
titleBar.Text = ""
titleBar.Parent = frame

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)
titleBar.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-20, 0, 26)
title.Position = UDim2.new(0, 12, 0, 8)
title.BackgroundTransparency = 1
title.Text = "⚡ UNIVERSAL FRAMEWORK v5.1"
title.TextColor3 = Color3.fromRGB(200, 150, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1,-20, 0, 16)
sub.Position = UDim2.new(0, 12, 0, 34)
sub.BackgroundTransparency = 1
sub.Text = ("%d kw · 16 strategies · tap title to drag"):format(TOTAL_KW)
sub.TextColor3 = Color3.fromRGB(140, 140, 160)
sub.Font = Enum.Font.Code
sub.TextSize = 9
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Parent = frame

local function mkBtn(x, y, w, text, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 34)
    b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(240,240,250)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.TextWrapped = true
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local scanBtn = mkBtn(12,  58, 130, 34, "🔍 SCAN",  Color3.fromRGB(60,40,100))
local dryBtn  = mkBtn(148, 58, 90,  34, "🧪 DRY",   Color3.fromRGB(60,60,30))
local liveBtn = mkBtn(244, 58, 90,  34, "🔥 LIVE",  Color3.fromRGB(100,30,30))
local copyBtn = mkBtn(340, 58, 88,  34, "📋 COPY",  Color3.fromRGB(40,70,90))

local verBtn  = mkBtn(12,  98, 130, 30, "🔎 VERIFY", Color3.fromRGB(30,60,80))
local repBtn  = mkBtn(148, 98, 130, 30, "📄 REPORT", Color3.fromRGB(50,50,70))
local stopBtn = mkBtn(284, 98, 144, 30, "⏹ STOP",    Color3.fromRGB(50,30,30))

local log = Instance.new("TextLabel")
log.Size = UDim2.new(1,-24, 1, -180)
log.Position = UDim2.new(0, 12, 0, 138)
log.BackgroundColor3 = Color3.fromRGB(6,8,12)
log.BorderSizePixel = 0
log.Text = "  ready — press SCAN"
log.TextColor3 = Color3.fromRGB(180,200,180)
log.Font = Enum.Font.Code
log.TextSize = 10
log.TextXAlignment = Enum.TextXAlignment.Left
log.TextYAlignment = Enum.TextYAlignment.Top
log.TextWrapped = true
log.Parent = frame
Instance.new("UICorner", log).CornerRadius = UDim.new(0, 6)

local running = false
local function setLog(t)
    log.Text = "  "..t
    logPush("UI " .. t)
end

-- ══════════════════════════════════════════════════════════════
-- 10 · COPY LOG
-- ══════════════════════════════════════════════════════════════
local function buildFullLog()
    local out = {
        "=== UNIVERSAL FW v5.1 — LOG DUMP ===",
        ("Place   : %d"):format(game.PlaceId),
        ("JobId   : %s"):format(game.JobId),
        ("Player  : %s (%d)"):format(LP.Name, LP.UserId),
        ("Remotes : %d"):format(Scan.stats.total or 0),
        ("Fired   : %d  OK: %d  Fail: %d  Det: %d"):format(
            Attack.fired, Attack.success, Attack.fail, Attack.detected),
        ("Keywords: %d"):format(TOTAL_KW),
        "",
        "--- TOP CANDIDATES ---",
    }
    for i, r in ipairs(Scan.remotes or {}) do
        if i > 150 then break end
        if r.score and r.score > 50 then
            out[#out+1] = ("[%4d] %s"):format(r.score, r.path)
        end
    end
    out[#out+1] = ""
    out[#out+1] = "--- LOG BUFFER ---"
    for _, line in ipairs(LOG_LINES) do
        out[#out+1] = line
    end
    return table.concat(out, "\n")
end

local function copyLog()
    local payload = buildFullLog()

    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard, payload)
        if ok then
            setLog(("copied %d chars"):format(#payload))
            return true
        end
    end

    if type(writefile) == "function" then
        local fn = "fw_log_"..game.PlaceId.."_"..os.time()..".txt"
        local ok = pcall(writefile, fn, payload)
        if ok then
            setLog("saved: "..fn)
            return true
        end
    end

    pcall(function()
        local tb = Instance.new("TextBox")
        tb.Text = payload
        tb.Size = UDim2.new(0, 1, 0, 1)
        tb.Position = UDim2.new(0, -100, 0, -100)
        tb.TextEditable = true
        tb.ClearTextOnFocus = false
        tb.Parent = frame
        tb:CaptureFocus()
        task.wait(0.1)
        tb.SelectionStart = 1
        tb.CursorPosition = #payload + 1
        task.wait(0.1)
        tb:ReleaseFocus()
        tb:Destroy()
    end)
    setLog("copy attempted via TextBox")
    return true
end

-- ══════════════════════════════════════════════════════════════
-- 11 · BUTTON WIRING
-- ══════════════════════════════════════════════════════════════
scanBtn.MouseButton1Click:Connect(function()
    if running then return end
    running = true
    setLog("scanning...")
    task.spawn(function()
        scan()
        setLog(("scan done\nremotes=%d\ncandidates≥80=%d"):format(
            Scan.stats.total,
            (function() local c=0 for _,r in ipairs(Scan.remotes) do if r.score and r.score>=80 and not r.detail.blocked then c=c+1 end end return c end)()
        ))
        running = false
    end)
end)

local function runAttack()
    if running then return end
    if #Scan.remotes == 0 then setLog("scan first") return end
    running = true
    setLog(("[attack] %s"):format(CONFIG.DRY_RUN and "DRY" or "LIVE"))
    task.spawn(function()
        attack()
        setLog(("done\nfired=%d ok=%d det=%d"):format(Attack.fired, Attack.success, Attack.detected))
        running = false
    end)
end

dryBtn.MouseButton1Click:Connect(function()
    CONFIG.DRY_RUN = true
    setLog("mode: DRY")
    runAttack()
end)

liveBtn.MouseButton1Click:Connect(function()
    CONFIG.DRY_RUN = false
    setLog("mode: LIVE ⚠️")
    runAttack()
end)

copyBtn.MouseButton1Click:Connect(function()
    copyLog()
end)

verBtn.MouseButton1Click:Connect(function()
    task.spawn(function() setLog("verifying...") verify() setLog("verify done") end)
end)

repBtn.MouseButton1Click:Connect(function()
    task.spawn(function()
        setLog("reporting...")
        local lines = {"=== UNIVERSAL FW v5.1 ===", ("Place: %d"):format(game.PlaceId)}
        lines[#lines+1] = ("Remotes: %d"):format(Scan.stats.total)
        lines[#lines+1] = ("Fired: %d Success: %d Detected: %d"):format(Attack.fired, Attack.success, Attack.detected)
        lines[#lines+1] = ""
        for i, r in ipairs(Scan.remotes) do
            if i > 100 then break end
            if r.score and r.score > 50 then
                lines[#lines+1] = ("[%d] %s"):format(r.score, r.path)
            end
        end
        local payload = table.concat(lines, "\n")
        if type(writefile) == "function" then
            local fn = "fw_report_"..game.PlaceId.."_"..os.time()..".txt"
            pcall(writefile, fn, payload)
            setLog("saved: "..fn)
        end
        if type(setclipboard) == "function" then
            pcall(setclipboard, payload)
            setLog("copied to clipboard")
        end
    end)
end)

stopBtn.MouseButton1Click:Connect(function()
    CONFIG.DRY_RUN = true
    running = false
    setLog("stopped")
end)

-- ══════════════════════════════════════════════════════════════
-- BOOT
-- ══════════════════════════════════════════════════════════════
print("╔══════════════════════════════════════════╗")
print("║  UNIVERSAL FRAMEWORK v5.1                ║")
print(("║  %d keywords · 16 strategies          ║"):format(TOTAL_KW))
print("╚══════════════════════════════════════════╝")
print("[ENV] getgc="..tostring(type(getgc)=="function")..
      " getnil="..tostring(type(getnilinstances)=="function")..
      " clipboard="..tostring(type(setclipboard)=="function")..
      " writefile="..tostring(type(writefile)=="function"))
print("[GUI] loaded")
