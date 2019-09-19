import argparse
import os
import datetime
import logging
import json
import itertools
import sys
from copy import copy


RAND_SEED = 1337


def cart_prod_dict(d):
    return (dict(zip(d, x)) for x in itertools.product(*d.values()))


def vals_to_str(v):
    if isinstance(v, list):
        return " ".join(vals_to_str(k) for k in v)
    else:
        return str(v)


if __name__ == "__main__":

    parser = argparse.ArgumentParser()

    parser.add_argument("config",
                        help="Path to json config file",
                        type=str)
    parser.add_argument("-d", "--defaults",
                        help="Path to json config file containing defaults",
                        default='defaults.json',
                        type=str)
    parser.add_argument("-s", "--script-name",
                        help="Path to script to gen grid for",
                        default='synth_exp.py',
                        type=str)
    parser.add_argument("--seeds",
                        help="list of seeds to replicate runs",
                        nargs='+',
                        default=None,
                        type=int)
    parser.add_argument("-e", "--env",
                        help="Bash environment string",
                        default='',
                        type=str)

    args = parser.parse_args()

    #
    # reading defaults from json
    defaults = None
    with open(args.defaults) as f:
        defaults = json.load(f)

    #
    # load specific configs
    config = None
    with open(args.config) as f:
        config = json.load(f)

    #
    # cartesian product of dictionaries
    configs = cart_prod_dict(config)

    for exp_id, c in enumerate(configs):

        seeds = None
        if not args.seeds:
            seeds = [RAND_SEED]
        else:
            seeds = args.seeds

        for seed in seeds:

            d = copy(defaults)
            d.update(c)

            #
            # create command string
            cmd = f"{args.env} {d['interpreter']} {args.script_name} {d['expname']}"
            d.pop('interpreter')
            d.pop('expname')

            cmd += f" --exp-id {exp_id} "

            cmd += f" --seed {seed} "

            for k, v in d.items():
                cmd += f" --{k} {vals_to_str(v)} "

            print(cmd)
