# Physics And Robot Bridge Team Presentation

This folder contains the team-facing presentation for the Stage 12 physics and robot bridge work.

## Main Files

| File | Purpose |
| --- | --- |
| `Stage12_Physics_Robot_Team_Update.pdf` | Presentation-ready slide deck |
| `Stage12_Physics_Robot_Team_Update.tex` | Editable LaTeX Beamer source |
| `source_notes.txt` | Source and provenance notes |
| `figures/` | Route, dashboard, and presentation figures |
| `preview/contact_sheet.png` | Quick visual preview of the slide deck |

## What The Deck Explains

- Why the project is moving from simplified speed tracking toward built-in Simulink physics blocks.
- How the Simscape Driveline `Longitudinal Vehicle` block fits the full-scale haul truck side.
- How the Robotics System Toolbox `Unicycle Kinematic Model` maps to Turtle-style robot motion.
- What the robot command handoff file means and how it maps to ROS `/cmd_vel`.
- What the current model supports and what still needs development.

## Important Interpretation

This is a bridge presentation, not a final validation claim.

The current full-scale Simscape side is a first stable loaded-outbound physics slice. It is useful for showing how an ML speed recommendation becomes a torque/brake command and then a physical vehicle response. It is not yet a complete OEM-grade haul truck dynamic model.

The robot side is a first command-handoff path. The command schedule is open-loop and should be tested safely before moving toward closed-loop path following.

## Rebuilding The PDF

From this folder, run:

```powershell
latexmk -pdf -interaction=nonstopmode -halt-on-error Stage12_Physics_Robot_Team_Update.tex
```

The deck uses the University of Arizona Beamer template files included in this folder.
