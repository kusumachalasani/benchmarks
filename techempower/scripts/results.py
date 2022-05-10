import os
import subprocess
import uuid
import time
import json
import requests
import threading
import re
import math
import csv
import traceback
from datetime import datetime


def parse_test(framework_test, test_type):
    '''
    Parses the given test and test_type from the raw_file.
    '''
    results = dict()
    results['results'] = []
    stats = []
    
    if os.path.exists("quarkus/reh"):
        with open("quarkus/reh/raw.txt") as raw_data:
            is_warmup = True
            rawData = None
            for line in raw_data:
                if "Queries:" in line or "Concurrency:" in line:
                    is_warmup = False
                    rawData = None
                    continue
                if "Warmup" in line or "Primer" in line:
                    is_warmup = True
                    continue
                if not is_warmup:
                    if rawData is None:
                        rawData = dict()
                        results['results'].append(rawData)
                    if "Latency" in line:
                        m = re.findall(r"([0-9]+\.*[0-9]*[us|ms|s|m|%]+)",
                                line)
                        if len(m) == 4:
                            rawData['latencyAvg'] = m[0]
                            rawData['latencyStdev'] = m[1]
                            rawData['latencyMax'] = m[2]
                    if "requests in" in line:
                        m = re.search("([0-9]+) requests in", line)
                        if m is not None:
                            rawData['totalRequests'] = int(m.group(1))
                    if "Socket errors" in line:
                        if "connect" in line:
                            m = re.search("connect ([0-9]+)", line)
                            rawData['connect'] = int(m.group(1))
                        if "read" in line:
                            m = re.search("read ([0-9]+)", line)
                            rawData['read'] = int(m.group(1))
                        if "write" in line:
                            m = re.search("write ([0-9]+)", line)
                            rawData['write'] = int(m.group(1))
                        if "timeout" in line:
                            m = re.search("timeout ([0-9]+)", line)
                            rawData['timeout'] = int(m.group(1))
                    if "Non-2xx" in line:
                        m = re.search("Non-2xx or 3xx responses: ([0-9]+)",line)
                        if m != None:
                            rawData['5xx'] = int(m.group(1))
                    if "STARTTIME" in line:
                        m = re.search("[0-9]+", line)
                        rawData["startTime"] = int(m.group(0))
                    if "ENDTIME" in line:
                        m = re.search("[0-9]+", line)
                        rawData["endTime"] = int(m.group(0))
                        print("this is end" + str(rawData["endTime"]) + " " + framework_test + " " + test_type )
                        test_stats = parse_stats(framework_test, test_type, rawData["startTime"], rawData["endTime"], 1)
                        stats.append(test_stats)
    with open("quarkus/reh/stats.txt.json", "w") as stats_file:
        json.dump(stats, stats_file, indent=2)

    return results

def parse_stats(framework_test, test_type, start_time, end_time, interval):
    '''
    For each test type, process all the statistics, and return a multi-layered
    dictionary that has a structure as follows:
    (timestamp)
    | (main header) - group that the stat is in
    | | (sub header) - title of the stat
    | | | (stat) - the stat itself, usually a floating point number
    '''
    stats_dict = dict()
    stats_file = "quarkus/reh/stats.txt"
    with open(stats_file) as stats:
        # dstat doesn't output a completely compliant CSV file - we need to strip the header
        for _ in range(4):
            stats.next()
        stats_reader = csv.reader(stats)
        main_header = stats_reader.next()
        sub_header = stats_reader.next()
        time_row = sub_header.index("epoch")
        int_counter = 0
        for row in stats_reader:
            time = float(row[time_row])
            int_counter += 1
            if time < start_time:
                continue
            elif time > end_time:
                return stats_dict
            if int_counter % interval != 0:
                continue
            row_dict = dict()
            for nextheader in main_header:
                if nextheader != "":
                    row_dict[nextheader] = dict()
            header = ""
            for item_num, column in enumerate(row):
                if len(main_header[item_num]) != 0:
                    header = main_header[item_num]
                # all the stats are numbers, so we want to make sure that they stay that way in json
                row_dict[header][sub_header[item_num]] = float(column)
                stats_dict[time] = row_dict
    return stats_dict

def get_stats_file(test_name, test_type):
        '''
        Returns the stats file name for this test_name and
        Example: fw_root/results/timestamp/test_type/test_name/stats.txt
        '''
        path = os.path.join(test_name, test_type, "stats.txt")
        try:
            os.makedirs(os.path.dirname(path))
        except OSError:
            pass
        return path

parse_test("quarkus", "reh")
