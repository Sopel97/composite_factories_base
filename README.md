# Composite Factories: Base

This is a mod for factorio. It's main premise is to reduce the tediousness of creating basic factories everywhere and reduce the impact on UPS.

It's currently in a very early stage of developement, not on mod portal.

The way this mod will work is it will allow the player to "craft" a single factory building that replaces some chunk of production. The costs will reflect the actual materials needed to build such a factory and each such composite factory recipe will be made based on a real blueprint (each such blueprint can be found in the blueprints folder). The "craft" is in quotation marks because having recipes with potentially tens or hundreds of ingredients is infeasible. The "crafting" will work by having a large inventory where the player will be able to dump the ingredients and a GUI will allow selection of factories that can be built from the components.

This mod is only the base and any machines can be added by other mods by utilizing public facing API of this base mod.

NOTE: To use this mod you need to make you own mod that uses this one as a library. For a simple example see https://mods.factorio.com/mod/composite_factories_example