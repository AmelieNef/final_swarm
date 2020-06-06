import math
import subprocess
import re
from math import inf

def create_dico(values):
    """
    Function to dictionnary with all initials values attach at each key
    :param values: list of integer values
    :return: dictionnary with value attached to parameters
    """

    keys = ["STOCHASTIC_2", "STOCHASTIC_3", "DECISION_COLLECTIVE"]

    dico = {}

    for i in range(len(keys)):
        dico[keys[i]] = values[i]

    return dico


def create_replaced(dico):
    """
    Function to create the replaced string for lua files
    :param dico: dictionnary with all value to replace in the Lua File
    :return:
    """
    replaced = ""

    for key in dico:
        replaced += key + " = " + str(dico[key]) + " \n"

    return replaced


def modify_lua(replaced):
    """
    Function to update lua file
    :param replaced: String containing all values
    :return: /
    """
    # Read in the file
    with open('pso_solution_template.lua', 'r') as file:
        filedata = file.read()

    # Replace the target string
    with_values = filedata.replace("###PARAMETERS###", replaced)

    # Write the file out again
    with open('pso_solution_exec.lua', 'w') as file:
        file.write(with_values)


def modify_argos_1(seed, best_personal):
    """
    Function to update Argos File
    :param seed: seed to put in the ARGOS file
    :param best_personal: lenght to put in the ARGOS file
    :return: /
    """
    # Read in the file
    with open('passerelle.argos', 'r') as file:
        filedata = file.read()

    # Replace the target string
    with_values = filedata.replace("###SEED###", str(seed))

    if best_personal > 43000:
        best_personal = 4300
    else:
        best_personal = math.ceil(best_personal / 10)

    print("threshold", best_personal)
    # Replace the target string
    with_values = with_values.replace("###LENGHT###", str(best_personal))

    # Write the file out again
    with open('passerelle_exec.argos', 'w') as file:
        file.write(with_values)

def get_number_of_steps(output):
    """
    Function to go extract the number of step in a file
    :param output: Output of the ARGOS process
    :return: number of step
    """
    pattern = re.compile("Experiment ends at: ([0-9]+)")
    found = pattern.search(output)
    if found is not None:
        return int(found.group(1))

    else:
        return inf



def main_interface(parameter_vector, seed, best_personal):
    """
    Function main
    :return: number of step obtain during execution
    """
    print("best_personal",best_personal)
    dico = create_dico(parameter_vector)
    replace = create_replaced(dico)
    modify_lua(replace)
    modify_argos_1(seed, best_personal)
    result = subprocess.run(
        ["argos3", "--no-color", "-c",
         "passerelle_exec.argos"],
        stdout=subprocess.PIPE, universal_newlines=True)

    return get_number_of_steps(result.stdout)
