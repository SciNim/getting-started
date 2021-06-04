import nimib, nimibook
import ggplotnim

nbInit()
nbUseNimibook

nbText: """
# Simple plotting using [ggplotnim](https://github.com/Vindaar/ggplotnim)

## Line plot
"""

nbCode:
  import ggplotnim
  let x1 = @[0.0, 1.0, 2.0, 3.0]
  let y1 = @[0.0, 1.0, 4.0, 9.0]
  let df1 = seqsToDf(x1, y1)
  ggplot(df1, aes("x1", "y1")) +
    geom_line() +
    ggsave("images/line_plot.png")

nbImage("images/line_plot.png")

nbText: """## Scatter plot"""
nbCode:
  import ggplotnim
  let x2 = @[0.0, 1.0, 2.0, 3.0]
  let y2 = @[0.0, 1.0, 4.0, 9.0]
  let df2 = seqsToDf(x2, y2)
  ggplot(df2, aes("x2", "y2")) +
    geom_point() +
    ggsave("images/scatter_plot.png")

nbImage("images/scatter_plot.png")

nbText: """
Notice how similar the two code snippet were. This is the general structure of ggplotnim, you add geoms and combine them in different way.
Try for yourself what happens if you have *both* `geom_line` and `geom_point`.
"""

nbSave
