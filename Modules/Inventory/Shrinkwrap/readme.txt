This folder has been created to "freeze" certain dependencies at certain points in time.

This will allow for better forwards-compatibility, as some of BetterUI's classes are VERY brittle.

If there are future updates that add great features to the default interface, the shrinkwrapped
modules can be replaced easily. 

I have re-named the original Zenimax dependencies so that they can function properly with the original 
code running behind it. The shrinkwrapped modules will have the prefix "ZOS_" rather than "ZO_" to distinguish
between the two.

prasoc