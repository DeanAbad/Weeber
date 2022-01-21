# Weeber
Weeber is a simple imageboard (booru) downloader that was built with the Godot Engine.

---

## Build Progress (Date Finished)
<blockquote>
January 21, 2022

- [x] Ordered tags by name
- [x] Fixed Tags list/section's reference for tags
- [x] Display that there are no results in the menu of images when the result is zero.
- [x] Removed stepify from adjusting the sizes of images

January 20, 2022

- [x] Added colors and count to tags
- [x] Added tags in Tags list/section

January 19, 2022

- [x] Responsive image menu size
- [x] Custom tooltip for displaying information i.e. <em>tags</em> when an image is hovered
- [x] Fixed leaked memory via free() and weakref()

</blockquote>

## Installation
There are no executable builds yet, but you can build it with the engine. Just clone the
repository and build it into any format.

## Features
- <em>Theme</em> - a painstakingly made Windows 10-inspired Theme resource that is reusable for varying Control nodes. <blockquote><em>Note:</em> There are still no options for directly including other Control nodes into the Theme inspector/editor, such as few from PopupDialog subsets. As
such, their styling are seperated from the main <em>default</em> Theme resource. Therefore,
these excluded ones are applied individually.</blockquote>

## Elements
Notes regarding the Scenes and their Theme resource.

### Scenes
- <em>AboutPopup and CustomToolTip</em> - they are empty nodes in the Main scene where the <em>custom_tool</em> will be instanced whenever images are being hovered or submenu buttons under Help menu button are clicked.

### Theme Resource
- <em>LineEdit</em> - its consists of 'no border' in visual as it is intended to be used under a <em>MarginContainer</em> parent, which itself is under a <em>PanelContainer</em> parent. The reason behind this is that the <em>caret</em> property of the LineEdit cannot have its appearanced be changed by any means, i.e. its skin and size, but only its blinking frequency and offset.


## Work in Progress
<blockquote>Maintenance: Other details will be added soon.</blockquote>