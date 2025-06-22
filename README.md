# Tcl Workshop 2025 

In this workshop we are focuing on the tcl scripting to lead us in the rtl2gds processing, the steps to get from an input constraints csv file and provided RTL level HDL files and libraries to synthesized design with completed timing analysis.
To achieve this, we first check design hierarchy, generate SDC file, do synthesis with YOSYS, format synthesis results and do timing analysis with OpenTimer. As a result, all useful information will be dispalyed in the console along with the resulting timing analysis resutls.

# Functionality of the shell script
One can easily check input validity and implement a useful help function in the shell script such as follows.
![image](https://github.com/user-attachments/assets/d7822d60-0032-410b-bc8c-2621f247a8c3)
Similar checking process can be done in tcl sciprt to ensure and double check.
![image](https://github.com/user-attachments/assets/5ae0d8b4-e415-4492-88ee-c1ecc6ee781a)
# SDC generation
With contraints cvs in hand, we generate the SDC constaraints related with clock and IO ports using search keyword of tcl and matrix csv file:
![image](https://github.com/user-attachments/assets/954930ce-d7d8-4f18-adc1-d95fff769e71)

Input port generation and output port constraint generation are done separetely:
![image](https://github.com/user-attachments/assets/eacd9a03-ab10-4b09-b5fd-6104a37f18e6)
![image](https://github.com/user-attachments/assets/550e3a36-1f93-4325-8d59-5465254f7d4d)
The resulting SDC file may look similar to the following:
![image](https://github.com/user-attachments/assets/041f5e3b-d6b1-43a8-8a03-fa26ee787b7b)
# Hierarchy Check in YOSYS
To ensure that the HDL files form a valid design with only one top module and submodules below it, we run the yosys hierarchy check before the main synthesis.
![image](https://github.com/user-attachments/assets/94161f08-c3b0-49fe-8adb-aefd913478ab)

# Main Synthesis File generation
We create the main synth file as follows and again execute YOSYS to synthesize fully:
![image](https://github.com/user-attachments/assets/c8e7d57c-1c6b-4930-afea-cc3bce91661c)

Main synthesis results will look like this in a succesfull case:
![image](https://github.com/user-attachments/assets/277e3742-b631-432b-bac3-d65e35c09966)

# Format Synth Results
In order to use OpenTimer for STA we have to format the synthesis results and forma a timing file using the read_sdc proc.

OpenTimer needs bit by bit expansion of busses and a specific format for constraints. Minding this, we build the timing file as follows:
![image](https://github.com/user-attachments/assets/d1a30819-ca9e-4464-b9cc-a88f2c859a18)

# Use OpenTimer for STA
Run OpenTimer for timing analysis and log results to user:
![image](https://github.com/user-attachments/assets/5b7b5a7c-57fa-4564-a944-64c5592bd8e5)

And hence the flow is complete.
