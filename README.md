# EEG-decoding
This repository describes a flexible workflow for parameterizing and executing models to decode MagnetoEncephaloGraphy (**MEG**)  and ElectroEncephaloGraphy (**EEG**) data.

The MEG and EEG models should be coded in Jupyter Notebooks. Our workflow is based on the tool [papermill](https://github.com/nteract/papermill) which runs a notebook from the command line with a customized set of parameters and saves the parameterized notebook and outcomes together as output. We build [gitmiller](https://pypi.org/project/gitmiller/) which is an extension to the papermill main package to run remote notebooks from github repositories.



## Installation
The instructions below are written with a Windows operating system in mind. Instructions for Mac OS or Linux are slightly different.

### Jupyter
If you would like to inspect or run a notebook interactively in the Jupyter Notebook interface, you need to have [Jupyter](https://jupyter.readthedocs.io/en/latest/install.html) installed. 
```
pip install jupyter
```
You can check your installation of Python and Jupyter by running (Windows command prompt):
```
where python
where jupyter
```
It is useful to change the default location that is opened in the Jupyter Notebook interface. To achieve this, first create a jupyter config file:
```
jupyter notebook --generate-config
```
The prompt will respond with a message like: "Writing default config to: <path>". Open the default config file, and look for the ```c.NotebookApp.notebook_dir``` option. Remove the '#' in front and set the option to the directory where you store your notebooks. Make sure to replace single directory separators '\\' with double '\\\\', e.g. "C:\\\\Users\\\\User\\\\Documents\\\\Notebooks".

### Gitmiller
The [papermill](https://github.com/nteract/papermill) package allows you to parameterize notebooks and execute these from the commandline. If these notebooks live in remote github repositories, you need to install [GitMiller](https://pypi.org/project/gitmiller/). GitMiller downloads the repository in your temp folder, runs the designated notebook within it using papermill, and removes all downloaded files afterwards. 
```
pip install gitmiller
```

### Git
You need to have Git installed if you would like to run the model from the
command line with papermill and our papermill-extension. Windows users can
[download Git here](https://git-scm.com/download/win), Mac users
[can use Homebrew](https://git-scm.com/book/en/v1/Getting-Started-Installing-Git#Installing-on-Mac).

### Matlab
To run the [MEG model](meg_models/PSR_MPVA_crossvalidation_fix_main.ipynb) in this repository you need to have Matlab installed. 

The model uses the CoSMoMVPA library. CoSMoMVPA is depending on the SVM
implementation of Matlab (R2017b or older; part of the Statistics / ML package).
The SVM implementation of Matlab R2019a is not compatible with the CoSMoMVPA
library anymore, so this requires an external library called ‘libsvm'.
The older versions of Matlab are not compatible with the latest version of Python.

Summarizing:
* When using Matlab R2019a, you need to install libsvm
* When using Matlab R2017b or older, you need Python 3.6

The next step is to install the [Matlab Engine API](https://nl.mathworks.com/help/matlab/matlab-engine-for-python.html) for Python.
The instructions listed below are based on [this guide](https://nl.mathworks.com/help/matlab/matlab_external/install-the-matlab-engine-for-python.html).

1. Locate the Matlab folder. You can do so by starting MATLAB and typing ```matlabroot``` in the command window. Alternatively, you can browse your "Program Files" folder for a folder called "MATLAB", and navigate to the subfolder of the most recent installed version (e.g. "R2017a"). The matlabroot path is generally something like: "C:\Program Files\MATLAB\R2017a".
2. Open a command window and enter the following commands:
```
cd "<matlabroot>\extern\engines\python"
python setup.py install
```

Note: Matlab Engine for Python does not support all Python versions. If the setup.py file can be run without problems, your default version is supported. Otherwise, you have to switch python versions.

### Install the Matlab kernel for Jupyter
We will be using [this Matlab kernel](https://github.com/Calysto/matlab_kernel). The instructions listed below are based on [this guide](https://github.com/Calysto/matlab_kernel/blob/master/README.rst).

1. Install the matlab_kernel package: ```pip install matlab_kernel```
2. Test the installation by running: ```jupyter notebook``` and selecting "Matlab" from the "New" menu in the notebook interface.

### FieldTrip
[Download the latest Fieldtrip toolbox](http://www.fieldtriptoolbox.org/download.php) into a convenient folder on your local harddrive. Note: the toolbox comes in a zip-file. After extracting you might end up with a folder _containing_ the toolbox folder. Move the toolbox folder out of the wrapping folder when this happens.

### CoSMoMVPA
The second required library is CoSMoMVPA. Download instructions
[can found here](http://www.cosmomvpa.org/download.html).

Note: the model needs both paths towards these libraries. If you download
this repo, you have to add these paths in the notebooks before running them.
If you want to run this model with papermill, the paths are expected as
parameters.



## Usage
The gitmiller commandline-interface requires several parameters which are described in [parameters.yaml](parameters.yaml).  If you would like to override certain variables in your notebook, add the variables and values in the yaml file under the papermill key. 

The [GitMiller repository](https://github.com/UtrechtUniversity/GitMiller/tree/master/example) contains a folder with an **example notebook**. To run this example create the following yaml file

    repository: https://github.com/UtrechtUniversity/GitMiller/tree/master/example
    username: <GITHUB USERNAME>
    password: <GITHUB PASSWORD>
    notebook: test.ipynb
    output: <PATH-TO-OUTPUT-FOLDER>
    
    papermill:
      a: 10
      b: 60

Run the notebook with
```
gitmiller -c <PATH-TO-YAML-FILE>
```


