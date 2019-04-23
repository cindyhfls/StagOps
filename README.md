# StagOps
code pertaining to the StagOps task in Strait et al., 2015

* Content *

% wrapper
1. main_wrap_plexon_stagops.m {wrap from plexons sorted MAT files}
2. main_wrap_population_stagops.m {wrap from ripple sorted MAT files and strobe files}
3. extractPSTHgeneric.m {extract psth from strobe to align from}

% behavior analysis
1. behavior_accuracy.m {change in accuracy over session progression, correct defined as the larger expected value item chosen}
2. get_some_vars.m {function to convert from Strait et al., 2015 to more variables}
3. subjective_value_calc.m {function to calculate the subjective value each session based on the probability of chosing gamble and probablity of gamble outcome}
4. choice_predictor.m {function to find regressors for choice}

% neural analysis
1. calc_tuning_slidwind.m {function to capture the change in tuning over trial timecourse for several variables}
