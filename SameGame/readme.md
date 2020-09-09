# Same Game (swift version)

Plays classic "same game" ball game:

- clusters of touching same-color balls can be removed; doing so scores
  the number of balls in the cluster squared (so: good to get large clusters
  on board before removing them)
  
- all balls less than 50 score +100 points (so: good to remove as many balls
  as possible at the end)
  
Demonstrates depth-first graph traversal, which is used to identify the
clusters of neighboring balls.

Uses Apple's SpriteKit, which is quite a delightful graphic game/physics
library. 