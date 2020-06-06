import random
from math import inf
import interface

# Parameter PSO
NUMBER_OF_PARTICLE = 20
PHI_1 = 1
PHI_2 = 1

# Other parameter
NUMBER_MAX_OF_ITERATION = 10
NUMBER_OF_PARAMETERS = 3
RANGE_PARAMETERS = [(0, 1), (0, 1), (0, 1)]


def create_topology(index):
    """
    Function to create the topology of my network
    :param index: Integer to specify opology choosing
    :return: a matrix with a list of neighbors for each particle, an a string designate the type of topology
    """
    if index == 0:
        type = "Fully_connected"
        topology = [tuple(i for i in range(NUMBER_OF_PARTICLE) if i != j) for j in range(NUMBER_OF_PARTICLE)]


    elif index == 1:
        type = "Ring"
        topology = [tuple([NUMBER_OF_PARTICLE - 1, 1])]

        middle = [tuple([i - 1, i + 1]) for i in range(1, NUMBER_OF_PARTICLE - 1)]
        for elem in middle:
            topology.append(elem)

        topology.append(tuple([NUMBER_OF_PARTICLE - 2, 0]))


    else:
        type = "Wheels"
        center = random.randint(0, NUMBER_OF_PARTICLE - 1)
        topology = [[center] for i in range(NUMBER_OF_PARTICLE - 1)]
        topology = topology[:center] + [tuple([i for i in range(NUMBER_OF_PARTICLE) if i != center])] \
                   + topology[center:]

    return topology, type


def get_random_position():
    """
    Function to obtain a vector position randomized
    :return: vector position randomized
    """
    random_position = []
    for range_parameters in RANGE_PARAMETERS:
        random_position.append(random.uniform(range_parameters[0], range_parameters[1]))
    return random_position


def check_bound(parameter, lower_bound, upper_bound):
    """
    Function to verify next position
    :param parameter: value of parameters
    :param lower_bound: minimum value of the parameter
    :param upper_bound: maximum value of the parameter
    :return: adjusted or not parameter
    """
    if parameter < lower_bound:
        return lower_bound
    elif parameter > upper_bound:
        return upper_bound
    else:
        return parameter


def function_objective(vector_position, seed_choosing, best_personal):
    """
    Function to compute quality value
    :param vector_position: list with the values of parameters
    :param seed_choosing: seed of the turn
    :param best_personal: maximum lenght of the lua execution
    :return:
    """
    number_of_step = interface.main_interface(vector_position, seed_choosing, best_personal)

    return number_of_step


def update_global_best(dico, best):
    """
    Function to update global best value
    :param dico: dictionnary containing all data
    :param best: best value obtain during the step
    :return: updated dictionnary
    """
    for particule in range(NUMBER_OF_PARTICLE):
        dico[particule]["best_global_position"] = best

    return dico


def update_local_best(dico, topology, most_best_local):
    """
     Function to update the local_best
    :param dico: dictionnary containing all data
    :param topology: topology actual
    :param most_best_local: the best previous local value
    :return:  updated dictionnary, updated or not most best local value
    """
    for particule in range(NUMBER_OF_PARTICLE):

        local_best = dico[particule]["best_personal_position"]

        for neighborhood in topology[particule]:
            if dico[neighborhood]["best_personal_position"][1] < local_best[1]:
                local_best = dico[neighborhood]["best_personal_position"]

        dico[particule]["best_global_position"] = local_best

        if most_best_local[1] > local_best[1]:
            most_best_local = local_best

    return dico, most_best_local


def create_particle(topology, type_topology, seed_choosing):
    """
    Function to initialyze the repertory of the particule
    :param topology: matrix of the neighboors choosing
    :param type_topology: string of the topology
    :param seed_choosing: integer choosing for the run
    :return: dictionnary updated, best value obtain during this step
    """
    list_dico = []
    best_particule = ([], inf)
    best_local = ([], inf)

    for particle in range(NUMBER_OF_PARTICLE):
        print(particle)
        dico = {}
        dico["position"] = get_random_position()
        dico["velocity"] = [0 for i in range(NUMBER_OF_PARAMETERS)]
        dico["best_personal_position"] = (dico["position"], function_objective(dico["position"], seed_choosing, inf))

        if dico["best_personal_position"][1] < best_particule[1]:
            best_particule = dico["best_personal_position"]

        dico["best_global_position"] = 0

        list_dico.append(dico)

        print(best_particule)

    if type_topology == "Fully_connected":
        list_dico = update_global_best(list_dico, best_particule)
    else:
        list_dico, best_local = update_local_best(list_dico, topology, best_local)

    return list_dico, best_local


def evaluate_quality(dico, best_global, seed_choosing):
    """
    Function to evaluate the quality at the current position and update value keeping of the particle
    :param dico:dictionnary with all data
    :param best_global: best value obtain during all previous step
    :param seed_choosing: integer of seed choosing for the step
    :return: updated dictionnary, best value obtained
    """
    quality = function_objective(dico["position"], seed_choosing, dico["best_personal_position"][1])

    if quality < dico["best_personal_position"][1]:
        dico["best_personal_position"] = (dico["position"], quality)

    if quality < best_global[1]:
        best_global = (dico["position"], quality)

    return dico, best_global


def update_particle(particle, inertia):
    """
    Function to update parameter of the particle
    :param particle: dictionnary obtain with all data
    :param inertia:value of inertia for this step
    :return: updated dictionnary
    """

    for dimension in range(NUMBER_OF_PARAMETERS):
        U_1 = random.uniform(0, 1)
        U_2 = random.uniform(0, 1)

        parenthese_1 = particle["best_personal_position"][0][dimension] - particle["position"][dimension]
        substep_1 = PHI_1 * U_1 * parenthese_1

        parenthese_2 = particle["best_global_position"][0][dimension] - particle["position"][dimension]
        substep_2 = PHI_2 * U_2 * parenthese_2

        particle["velocity"][dimension] = (inertia * particle["velocity"][dimension]) + substep_1 + substep_2

        particle["position"][dimension] = check_bound(particle["position"][dimension] + particle["velocity"][dimension],
                                                      RANGE_PARAMETERS[dimension][0], RANGE_PARAMETERS[dimension][1])

    return particle


def move_swarm(swarm, topology, type_topology, seed_choosing, inertia, best_local):
    """
    Function to apply update on all particle
    :param swarm: dictionnary with all data
    :param topology: matrix with all neighbors
    :param type_topology: type of the topology choosing
    :param seed_choosing: integer of the seed obtain for this step
    :param inertia: value of inertia for this step
    :param best_local: best value local obtain previously
    :return: updated dictionnary, updated or not best value
    """
    best_global = swarm[0]["best_global_position"]

    for particle in range(NUMBER_OF_PARTICLE):
        print(particle)
        swarm[particle] = update_particle(swarm[particle], inertia)
        swarm[particle], best_global = evaluate_quality(swarm[particle], best_global, seed_choosing)
        print(best_global)
    if type_topology == "Fully_connected":
        swarm = update_global_best(swarm, best_global)
    else:
        swarm, best_local = update_local_best(swarm, topology, best_local)

    return swarm, best_local


def main():
    """
    Function main to the program
    :return:/
    """
    print("Beginning of PSO execution")

    topology, type_topology = create_topology(0)
    print(topology)
    print(type_topology)

    before_seed_choosing = random.uniform(1, 100000)
    random.seed(before_seed_choosing)

    print("Step 0 : Initialization of particles")
    dico_particle, best_local = create_particle(topology, type_topology, before_seed_choosing)

    terminate = False
    step = 1

    inertia = 1.0
    while not terminate:
        print(best_local)
        print(f"Phi 1 {PHI_1}, Phi 2 {PHI_2}")
        seed_choosing_new = random.uniform(1, 100000)
        while seed_choosing_new == before_seed_choosing:
            seed_choosing_new = random.uniform(1, 100000)
        before_seed_choosing = seed_choosing_new
        random.seed(before_seed_choosing)

        print("Step " + str(step))
        dico_particle, best_local = move_swarm(dico_particle, topology, type_topology, before_seed_choosing,
                                               inertia,
                                               best_local)

        print("evaluation")

        step += 1

        inertia = inertia - 0.01

        if step == NUMBER_MAX_OF_ITERATION:
            terminate = True

    if type_topology == "Fully_connected":
        print("Best solution are found at step " + str(step - 1) + " with the value " +
              str(dico_particle[0]["best_global_position"][0]) + " and quality equal to " +
              str(dico_particle[0]["best_global_position"][1]))
    else:
        print("Best solution are found at step " + str(step - 1) + " with the value " +
              str(best_local[0]) + " and quality equal to " +
              str(best_local[1]))

    print("End of the PSO execution")


if __name__ == '__main__':
    main()
