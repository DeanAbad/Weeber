# Weeber
Weeber is a simple imageboard (booru) downloader that was built with the Godot Engine.

---

## Installation
There are no executable builds yet, but you can build it with the engine. Just clone the
repository and build it into any format.

---

## Features
 - <em>Theme</em> - a painstakingly made Windows 10-inspired Theme resource that is reusable for varying Control nodes. <blockquote><em>Note:</em> There are still no options for directly including other Control nodes into the Theme inspector/editor, such as few from PopupDialog subsets. As
such, their styling are seperated from the main <em>default</em> Theme resource. Therefore,
these excluded ones are applied individually.</blockquote>

---

## Nodes
Some notes regarding the Nodes and their Theme resource.

### Theme Resource
- <em>LineEdit</em> - its consists of 'no border' in visual as it is intended to be used under a <em>MarginContainer</em> parent, which itself is under a <em>PanelContainer</em> parent. The reason behind this is that the <em>caret</em> property of the LineEdit cannot have its appearanced be changed by any means, i.e. its skin and size, but only its blinking frequency and offset.

---

## Work in Progress
<blockquote>Maintenance: Other details will be added soon.</blockquote>