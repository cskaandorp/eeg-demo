# MEG-decoding
This folder contains a model to decode Magnetoencephalography (MEG) data and is coded in Matlab. The model uses an external library called CoSMoMVPA which starts the Machine Learning (SVM) process.  This library and its dependencies should be installed locally first (see instructions in the [main folder](../README.md)) before the model can be run as a Jupyter Notebook with GitMiller.


## Usage
Make sure you add the paths towards libsvm, the FieldTrip toolbox and
the CoSMoMVPA library to the YAML file. If you would like to override parameters in the model, you can add them under the papermill key in the YAML file. Please find [here](parameters_example.yaml) an example of such a YAML file.

Run the model with 
```
gitmiller -c <PATH-TO-YAML-FILE>
```
Please see below for a more detailed description of the input parameters, input data and output data of the meg model .

# Time-resolved decoding

This script uses Multivariate Pattern Analysis (MVPA) to decode certain stimulus properties from MEG or EEG data over time. The input dataset (per subject) should be a FieldTrip structure with fully preprocessed and timelocked M/EEG data. The structure should contain trial specific condition information for each property that will be decoded (in the data.trialinfo field, see section 2.1). Decoding is run with the CoSMoMVPA toolbox, using one of two classifiers: linear discriminant analysis (LDA) or a support vector machine (SVM). The subsets of data used for training and testing the classifier are balanced over the properties as defined in the parameter balance. The output dataset (per subject) is a structure that contains the average performance and sensitivity of the decoder over time for each specified property. This dataset can be plotted in order to depict the classification performance over time. The dataset could also be used as an input for subsequent permutation (i.e. for statistics).

## 1. Input parameters
The YAML file contains all parameters that can be altered. It can be opened as a simple .txt file with a text editor. The following parameters can be edited:

| Parameter | Description |
| --- | --- |
| displaynow | _true_ or _false_ whether to display all subject names found in folderIN (used in _PSR\_subjects_ function). Can be useful to double check whether the script finds all the subjects you want to process. |
| nchar | number of characters in subjectfile (used in _PSR\_subjects_), e.g. for file named ‘subject01’, nchar = 9 |
| timeradius | number of neighboring time indices used to compute neighborhood intervals for temporal 'searchlight' (used in _cosmo\_interval\_neighborhood_) |
| nfolds | number of folds for cross-validation |
| ptest | proportion of data used as test-set to assess classifier accuracy (used in _PSR\_mkCoSMoPartitions\_BALANCE_), e.g. ptest = 0.1 |
| suffix | Nx2 cell-array: {‘prop1’, col1; ‘prop2’, col2; ‘_propN_’, _colN_} where ‘prop’ is a string defining the to-be classified stimulus property and col represents the column number in data.trialinfo, containing trial specific condition information of the corresponding property (see section 2.1 for more info). Example: suffix = { 'SF', 3; 'OR', 4}. Spatial frequency and orientation will be classified. The trial specific spatial frequency conditions can be found in column 3 and those of orientation can be found in column 4 of data.trialinfo.<br>__N.B.__: The correct use of commas, semicolons and quotation marks in the cell-array is important! Also, the string (propN) will be used as fieldname in the output dataset (i.e. S1.accuracy.(propN), see section 4.1), so give your property a sensible suffix. |
| balance | Nx2 cell-array: {‘prop1’, col1; ‘prop2’, col2; ‘propN’, colN} of stimulus properties that should be balanced during partitioning. See suffix for explanation on the variables. |
| channels | 'EEG' or ‘MEG’ if all channels should be used for classification. If you don’t want all channels, define a Nx1 cell-array with the selection of channels that should be included in classification, e.g. channels = {‘Iz’; ‘Oz’; ‘POz’} (used in PSR_loadTimelock).<br>(See [the Fieldtrip Toolbox](http://www.fieldtriptoolbox.org/reference/ft_channelselection/) for more input options) |
| classifier | 'LDA' or 'SVM', type of classifier used (linear discriminant analysis or support vector machine) |

The folder necessary for running the scripts are defined in parameters.yaml as well. The folders should always be specified as a string containing the entire directory toward the folder, e.g. 

```folderFT = ‘/Users/Documents/MATLAB/Toolboxes/fieldtrip’``` 

(note: the quotation marks make it a string).

| Folder | Description |
| --- | --- |
| folderFT | folder with FieldTrip toolbox |
| folderCoSMoMVPA | folder with CoSMoMVPA toolbox |
| folderLIBSVM | folder with libsvm toolbox |
| folderIN | folder with to-be classified data (raw or timelocked ft dataset) |
| folderOUT | folder where output data will be saved |
| extension | string with the extension of the input datafile (now only '.mat’) |

## 2. Input: Fieldtrip dataset
Some background: For now, the script only works when the input data is in a fieldtrip (ft) format. The data can either be a ft ‘raw’ dataset (obtained after ft_preprocessing) or a ft ‘timelocked’ dataset (obtained after ft_timelockanalysis). The script will check whether or not the dataset is timelocked and will timelock if necessary. The ft timelocked format is necessary for later transformation to a CoSMoMVPA format (with cosmo_meeg_dataset). The dimensions in the timelocked dataformat are structured as: trials x channels x time (where time is often represented as samples/data points). The data is formatted as a structure with the following fields:

| Field | Value |
| --- | --- |
| time | [1×samples double] |
| label | {channels×1 cell} |
| sampleinfo | [trials×2 double] |
| trial | [trials×channels×samples double] |
| trialinfo | [trials×N double] |
| dimord | 'rpt_chan_time' |
| cfg |	[1×1 struct] |

### 2.1 trialinfo
The field data.trialinfo is the only thing that needs changing in order for the decoding scripts to work. It is important that data.trialinfo contains a column with condition information for each stimulus property of importance. In my dataset, e.g., the stimulus properties were spatial frequency (SF) and orientation (OR). There were two SF conditions (high vs. low SF) and two ORs conditions (left vs. right OR). This means that my data.trialinfo will require at least two columns: one with the SF condition per trial (i.e. which SF were participants looking at during a specific trial) and one with the OR condition per trial. The numbers used to indicate one or the condition can be arbitrary (as long as they are consistent, of course).<br>
A bit more practical: My original data.trialinfo already contains one column with the triggers I sent during data acquisition for all 4 conditions (2 SFs x 2 ORs) and one column with the trialnumbers of the trials that weren’t rejected in preprocessing. This means that my property specific trialinfo will be stored in the third and fourth column of data.trialinfo. I can use the condition info from my trigger column 1 to create separate columns for SF and OR conditions. See this small matlab code: 

```
triggerInfo  = data.trialinfo( : , 1 );
lowSF	     =  ( triggerInfo == 21 | triggerInfo == 22 );
highSF	     =  ( triggerInfo == 23 | triggerInfo == 24 );
data.trialinfo( lowSF , 3 )  = 1;
data.trialinfo( highSF , 3 ) = 2;
```

I find the trials in which the SF was low (i.e. triggers nr 21 & 22) and place a number 1 in that row of column 3. I do the same for the other SF (triggers nr 23 & 24), but I give those a number 2. The same can be done for the two OR conditions and that information is placed in column 4. It is important to remember which column contains which property info, because you’ll need to specify the columns in the parameters _suffix_ and _balance_.

## 3. CoSMoMVPA dataset
This is not something you necessarily need to know in order for the script to run smoothly. The input and output data are the only things you actually get to see, not the CoSMo data itself. However, we use the CoSMoMVPA toolbox to run all the decoding and a CoSMo dataset has certain features that might be interesting to know about. As I mentioned before, the ft dataset needs a certain format (derived from the function ft_timelockanalysis) in order for it to be transformed into a CoSMo dataset. For the transforming, we defined the function _PSR\_mkCoSMoData_. This function uses CoSMo’s [cosmo_meeg_dataset](http://cosmomvpa.org/matlab/cosmo_meeg_dataset.html) which transforms MEEG data into the proper format. Similar to a fieldtrip dataset, CoSMo arranges the data as a structure, with the following fields:

| Field | Value |
| --- | --- |
|.samples |	[trials × (samples x channels) double] |
|.fa | [1×1 struct] |
|.a | [1×1 struct] |
|.sa | [1×1 struct] |

It’s a bit out of the scope of this instruction to explain to content of all fields now, but there are some important things to note: CoSMoMVPA has a bit of a counterintuitive way of naming certain aspects of the dataset. CoSMo uses the word ‘samples’ to refer to your trials. So the field .sa (= sample attributes) contains all the information on trials. CoSMo’s ‘features’ refers to your data points, i.e. with most datasets this means that features are: sample/time points x channels. The field .fa (= feature attributes) consequently contains information on the channels and sample/time points. You can always check [this page](http://www.cosmomvpa.org/cosmomvpa_concepts.html) for more information on CoSMo datasets.

### 3.1 .sa (Sample attributes) 
Sample attributes (.sa) is the only field where we need to define stuff ourselves. And this (mostly) happens in _PSR\_mkCoSMoData_ too. In .sa we need at least two fields: sa.chunks (stating that all trials are independent) and sa.targets. The latter defines which trials belong to which condition and is used for training and testing the decoder. To be precise: sa.targets is a trials x 1 matrix that contains the condition info from one property (i.e. using the separate columns we defined in data.trialinfo, see section 2.1). (N.B. The actual definition of sa.targets happens later on in the main script, but in _PSR\_mkCoSMoData_ we lay the foundation). On top of the two required fields, we also define sa.type. Here we use the variable balance. Each condition of the properties that need to be balanced when making partitions will be given a number. In my dataset, you would want to balance both orientation and spatial frequency. Both properties have two conditions, so 4 conditions in total. This means that sa.type will be a trials x 1 matrix containing numbers from 1 to 4, stating which condition was presented in which trial.

### 3.2 decoding
Once the CoSMo dataset has been properly defined, we balance the trials (with our own _PSR\_mkCoSMoPartitions\_BALANCE_) and use that information to make balanced partitions (with [cosmo_balance_partitions](http://cosmomvpa.org/matlab/cosmo_balance_partitions.html)). Since we want to conduct time resolved decoding, we need a so called ‘neighborhood’ of timepoints (using [cosmo_interval_neighborhood](http://cosmomvpa.org/matlab/cosmo_interval_neighborhood.html)) with the size of the interval defined in _timeradius_. Next we run the (LDA or SVM) classifier per fold and per time point. The classifier is trained on a subset of the data and will be tested on another subset. The predictions resulting from this will be used for the output dataset.

## 4. Output dataset

### 4.1 What do we get?
The script automatically saves an output dataset for each participant (now the files are saved as ‘Subject01’, ‘Subject02’, etc.) in the specified output folder. Each output dataset is a matlab structure called ‘S1’. If you load the dataset of one participant into matlab and call S1, you see that the data has the following fields:

| Field | Value |
| --- | --- |
| y | [1×1 struct] |
| yhat | [1×1 struct] |
| time | [1× time double] |
| accuracy | [1×1 struct] |
| dprime | [1×1 struct] |

The field S1.time contains a vector with the timepoints converted from samples into seconds (which comes in handy when plotting, see 4.2). All other fields of S1 are structs on their own, containing separate fields for the decoded property that is specified in the parameter ‘suffix’. So if I call S1.accuracy for my dataset, I get the following:

| Field | Value |
| --- | --- |
| SF | [1×1280 double] |
| OR | [1×1280 double] |

Both SF and OR contain a vector with the average decoding accuracy (over all folds) over time. The accuracy is calculated using S1.y and S1.yhat. The first contains a matrix with the actual targets used for testing (per time point and fold). The latter is a similar matrix, but instead of the actual targets, it contains the predicted targets of the decoder over time. This way, the predictions can be compared to the actual test set, in order to calculate the predictor’s accuracy over time. This is stored in S1.accuracy. S1.dprime will depict the decoders sensitivity over time and per property.

### 4.2 How do you use it?

In order to access the accuracies of the SF decoding, you call S1.accuracy.SF. This can also be used to plot the accuracies: figure; plot( S1.accuracy.SF ). However, now you have sample number indexed on the x-axis. In order to get actual time in seconds on the x-axis, you can plot using two inputs: figure; plot( S1.time, S1.accuracy.SF ). In order to get the accuracies of all the subjects, you need some Matlab knowledge. You’ll probably want to loop through all subjects and put their accuracies in one big matrix. Then you can average and plot them all you like.