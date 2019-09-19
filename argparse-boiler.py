import argparse

try:
    from time import perf_counter
except:
    from time import time
    perf_counter = time

import datetime
import os
import sys
import logging
import pickle
import gzip
import json

import numpy as np
import numba

if __name__ == '__main__':

    #########################################
    # creating the opt parser
    parser = argparse.ArgumentParser()
    parser.add_argument("main", type=str,
                        help='main argument')

    parser.add_argument('-o', '--output', type=str,
                        default='./exp/',
                        help='Output path to exp result')

    parser.add_argument('--tuple', type=int, nargs='+',
                        default=(10, 7),
                        help='A tuple of integers')

    parser.add_argument('--seed', type=int, nargs='?',
                        default=1337,
                        help='Seed for the random generator')

    parser.add_argument('--exp-id', type=str,
                        default=None,
                        help='Dataset output suffix')

    parser.add_argument('--flag', action='store_true',
                        help='A boolean argument')

    parser.add_argument('-v', '--verbose', type=int, nargs='?',
                        default=1,
                        help='Verbosity level')
    #
    # parsing the args
    args = parser.parse_args()

    #
    # creating output dirs if they do not exist
    date_string = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    dataset_name = 'tempdata'

    if args.exp_id:
        out_path = os.path.join(args.output, args.exp_id)
    else:
        out_path = os.path.join(args.output,  '{}_{}'.format(dataset_name, date_string))
    os.makedirs(out_path, exist_ok=True)

    #
    # Logging
    log_formatter = logging.Formatter(
        "%(asctime)s [%(levelname)-5.5s] [%(filename)s:%(funcName)s:%(lineno)d]\t %(message)s")
    root_logger = logging.getLogger()

    # to file
    log_dir = os.path.join(out_path, 'logs')
    os.makedirs(log_dir, exist_ok=True)
    file_handler = logging.FileHandler(os.path.join(log_dir, f"{dataset_name}.log"))
    file_handler.setFormatter(log_formatter)
    root_logger.addHandler(file_handler)

    # and to console
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(log_formatter)
    root_logger.addHandler(console_handler)

    #
    # setting verbosity level
    if args.verbose == 1:
        root_logger.setLevel(logging.INFO)
    elif args.verbose == 2:
        root_logger.setLevel(logging.DEBUG)

    args_out_path = os.path.join(out_path, 'args.json')
    json_args = json.dumps(vars(args))
    logging.info("Starting with arguments:\n%s\n\tdumped at %s", json_args, args_out_path)
    with open(args_out_path, 'w') as f:
        f.write(json_args)

    #
    # setting up the seed
    rand_gen = np.random.RandomState(args.seed)

    out_log_path = os.path.join(out_path,  'exp.log')
    logging.info('Opening log file... {}'.format(out_log_path))
