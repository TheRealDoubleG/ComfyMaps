# ComfyMaps

**Version 0.2 – Beta**  
**Target: World of Warcraft: Forever 1.60.1 / Interface 16001**

Modular world map enhancements, coordinates, points of interest and map utilities for the Comfy Suite on WoW Forever.

ComfyMaps owns world-map presentation so other Comfy addons can provide map data without each addon modifying the Blizzard map independently.

## 0.2 Beta

- Profile changes now immediately reapply the active ComfyMaps feature settings.

## 0.1 Beta

### World map
- configurable scale and opacity
- optional lower opacity while moving
- optional decorative-border hiding
- unlock/drag handle with remembered position
- reset position

### Coordinates
- player coordinates
- cursor coordinates when the Forever map scroll container exposes normalized cursor position

### Comfy data
- optional ComfyGatherer node pins on the world map
- configurable Gatherer pin size and maximum visible pin count

The first release intentionally avoids map reveal, custom POI databases and aggressive map rewrites until the Forever runtime behavior has been validated.

The feature direction is inspired by useful map-enhancement concepts found in addons such as Leatrix Maps, while the implementation and code are original Comfy Suite work.
