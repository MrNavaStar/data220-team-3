# scripts/07_charts.R -- DATA 220 Lab 9, Part B: charts from YOUR project's data.
#
# HOW TO OPEN: open your project (project/project.Rproj), then this file. The working directory
# is then the project folder, so "data/interim/..." and "output/charts/..." are found.
# (Part A is a different project: lab9_warmup/lab9_warmup.Rproj.)
#
# Reads:  your cleaned tables (data/interim/*_clean.csv) or your database
# Writes: output/charts/B1_....png, output/charts/B2_....png, ...
#         output/ is rebuilt by scripts and is not in Git (see .gitignore). Your charts reach
#         us inside the PDF report.
#
# Run it on its own for Lab 9, after run_all.R has built your cleaned tables. Before the final
# project submission, add it to run_all.R so the charts are rebuilt with everything else.
#
# Draw at least FOUR charts, using at least THREE different chart types.
# Every chart has the same five parts -- copy the block below once per chart:
#   # PURPOSE: the question this chart answers (one of your project questions)
#   # CHART:   which chart type, and why it fits the question
#   the data step (filter / count / summarise, or a SQL query)
#   the ggplot, stored in a variable, with a title that states the finding, axis labels and
#   the source caption; then ggsave(..., plot = that variable)
#   # FINDING: what the chart shows, in one or two sentences, with a number
#
# Which chart for which question (Week 11 reader, section 10):
#   How many in each category?            bar chart     geom_bar() / geom_col()
#   What values does one number take?     histogram     geom_histogram(binwidth = )
#   How does it change over time?         line chart    geom_line()
#   Do two numbers move together?         scatter plot  geom_point(alpha = )
#   A number across groups?               box plot      geom_boxplot()
library(ggplot2)
library(dplyr)
dir.create("output/charts", recursive = TRUE, showWarnings = FALSE)

# Replace this text ONCE, here. Every chart below reuses it with caption = SOURCE,
# so no chart is left saying "TODO".
SOURCE <- "Source: TODO (where your data comes from, and the date you collected it)"

# ---- read your cleaned tables ----------------------------------------------------------
# From the cleaned CSV files that 02_clean.R wrote:
#   sales <- read.csv("data/interim/sales_clean.csv")
# read.csv() reads dates as text, so convert them again:
#   sales <- sales |> mutate(date = as.Date(date))
#
# Or from your database (Week 9), if you have built it:
#   library(DBI)
#   con <- dbConnect(RSQLite::SQLite(), "data/db/project.sqlite")
#   sales <- dbGetQuery(con, "SELECT * FROM sales")
#   dbDisconnect(con)

# your tables here


# =============================== B1 ====================================================
# PURPOSE: TODO
# CHART:   TODO
#
# Example of a finished block, the same one as on page 3 of the handout
# (delete it and write your own):
#   # PURPOSE: Which menu items bring in the most money?
#   # CHART:   bar chart -- one bar per item (a category), sorted by size.
#   item_revenue <- sales |>
#     group_by(item) |>
#     summarise(revenue = sum(revenue))
#   b1 <- ggplot(item_revenue, aes(x = revenue, y = reorder(item, revenue))) +
#     geom_col(fill = "steelblue") +
#     labs(title = "Lattes and drip coffee bring in half of the cart's revenue",
#          x = "Revenue, Sep-Oct 2026 (dollars)", y = NULL, caption = SOURCE)
#   b1        # typing the name draws the chart
#   ggsave("output/charts/B1_revenue_by_item.png", plot = b1, width = 7, height = 4, dpi = 150)
#   # FINDING: Lattes earned $8,778 and drip coffee $7,007: together 51% of the $30,830 total.
#   #          Hot chocolate earned the least ($2,644).

# your chart B1 here

# FINDING: TODO


# =============================== B2 ====================================================
# PURPOSE: TODO
# CHART:   TODO

# your chart B2 here

# FINDING: TODO


# =============================== B3 ====================================================
# PURPOSE: TODO
# CHART:   TODO

# your chart B3 here

# FINDING: TODO


# =============================== B4 ====================================================
# PURPOSE: TODO
# CHART:   TODO

# your chart B4 here

# FINDING: TODO


# More charts? Copy a block and call it B5, B6 ...
