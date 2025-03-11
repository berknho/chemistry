# Learning Curves: Examining Post-Trade-Deadline Pitcher and Catcher Relationships

**Authors:**  
- Berkeley N. Ho  
- Leonardo Robles-Lara  
- Christian D. Franco  
- Hayden A. Dunn

## Research Question and Context

### Motivation

In professional baseball, communication between pitchers and catchers is fundamental to team success.  
These duos are the heart of a team's defensive strategy, working in unison to prevent opposing hitters from converting plate appearances into runs.  
Generally, pitchers are responsible for metrics related to ball-control, including their velocity, spin rate, and movement.  
Notably, catchers have the crucial role of framing pitches, which can significantly influence the outcome of an at-bat.  

In optimal situations, catchers who frame well can reduce the number of pitches a pitcher has to throw, while less skilled catchers can have the opposite effect.  
Additionally, catchers "call games," or dictate which pitch type to throw in a given situation.  
Although scouting reports and coaches provide a game plan on how to face batters, it is up to both the pitcher and catcher to execute any in-game adjustments.  

Before the regular season starts for Major League Baseball (MLB), spring training games provide a competitive-but-low-stakes setting for pitchers and catchers to acclimate to each another.  
However, the League's annual Trade Deadline provides a unique opportunity for analysis.  
It marks the final date when teams can trade players, typically occurring with about one-third of the season's games remaining.  
Players who are traded are then expected to immediately relocate and play for a new team, who have often brokered deals to supplement or fill roles necessary when competing for a playoff spot.  
Thus, the post-trade period acts as an observational study in which we can analyze how pitcher-catcher relationships develop in a more high-pressure context.

### Research Question

Presently, there exists sociological literature on team chemistry in a variety of contexts, including sporting and non-sporting fields.  
Within sport settings, research has been conducted to model relationships via networks for both the men's National Basketball Association (NBA) and MLB.  
In the MLB, Wins Above Replacement (WAR) has been used to model the best arrangement of players.  
While the use of empirical analysis in baseball has grown exponentially since the sport's inception, there still remains a gap in the literature in formally quantifying or attempting to measure chemistry between individuals directly, including pitchers and catchers.  

Thus, the aim of our project is to determine a method to quantify how "chemistry" develops via pitcher-catcher performance after trade deadlines.

### Objective

As part of our goal in quantifying chemistry between pitchers and catchers, we have several objectives:  
- Can we determine what variables are most correlated to performance on a short and long term performance basis?  
- Can we produce a measurable statistic on how acquiring a player would impact a team's immediate performance vs. games down the stretch?  
- Can we provide a timeline for when peak performance or chemistry is first attained, or produce a curve of how chemistry develops across time?

## Data Sources

To investigate these objectives, we will be using data aggregated from several sources.  
We will primarily pull data from recent pitchers or catchers who were traded after the start of the season as examples of relationships that do not yet have "chemistry."  
This will operate under the assumption that those pitchers and catchers have not played together before in any professional context.

Ideally, data post pitch-clock-implementation (start of 2023 season) would provide enough of a sample size for pitchers and catchers.  
However, if there is not a large enough sample size, additional seasons would be considered.  
It would be important to also consider other major rule changes or conditions, including how the composition of baseballs in recent seasons has led to discussions on whether balls are "juiced," leading to changes in batting performance compared to previously.  
As a result, pitcher and catcher performance should be sampled with these changes in mind.

- [Baseball Savant](https://baseballsavant.mlb.com/)  
- [Baseball Reference](https://www.baseball-reference.com/)  
- [MLB.com](https://www.mlb.com/)

Additionally, there are several R packages including `baseballr` from which we expect to pull and clean data.

Granular data including pitch-level data will be useful in looking at how a pitcher's ball movement might change and overall pitch composition.  
Individual pitch-level data also provides more context on how performance is in the context of a game's situation.  
In addition, game-level data can also be useful for summarizing how performance changes as time increases.  
This would operate on the assumption that chemistry would increase as time increases.

### Primary Variables

#### Pitchers
- Velocity  
- Movement  
- Pitch Composition  
- Strikeout Percentage  
- Walks per Nine Innings  
- Fielding Independent Pitching

#### Catchers
- Passed Balls  
- Catcher Framing Runs  
- Blocks Above Average

## Methodology

To quantify how "chemistry" develops between pitchers and catchers after the trade deadline, we will employ a combination of linear regression and machine learning techniques, including XGBoost and ensemble methods.  
These methods are well-suited to model relationships in our data and provide insights into the performance dynamics between pitcher-catcher duos.

Linear regression will be used to analyze the relationship between pitcher-catcher performance metrics and their impact on overall team performance.  
This method will allow us to quantify the influence of individual variables, such as pitch velocity, framing runs, and strikeout rates, on outcomes like ERA and team win-loss records after trades.

We will also use machine learning techniques, such as XGBoost and ensemble methods.  
XGBoost is more adept at handling complex, non-linear relationships in large datasets.  
This will help us identify interactions between pitcher and catcher metrics that linear models might overlook.  
Ensemble methods will be utilized to combine multiple models, improving prediction accuracy by reducing overfitting.

To better understand the data and model results, we will create various visualizations to illustrate performance trends over time.  
These may include time-series plots, heatmaps for feature importance, and scatterplots analyzing performance.  
Additionally, we will use model validation techniques, such as cross-validation, to assess the generalizability of our models.  
This ensures that our predictions on pitcher-catcher performance are reliable and not overly specific to the training data.
