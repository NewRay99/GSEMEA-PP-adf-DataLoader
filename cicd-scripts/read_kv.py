import json


def read_kv(env: str, cfg_file: str) -> dict:
    """
    Reading standard cfg from JSON file.
    The actual values for each key used in the deployment are partitioned by a given
    environment.
    :param env: deployment environment (e.g. dev, stg, prd)
    :type env: str
    :param cfg_file: relative path to the config file
    :type cfg_file: str
    :return: parsed configuration
    :rtype: dict
    """
    file = open(cfg_file)
    whole_kv = json.load(file)
    file.close()
    kv_keys = [*whole_kv.keys()]
    kv = dict()
    for x in kv_keys:
        kv[x] = [whole_kv.get(x).get(
            'type'), whole_kv.get(x).get('Env').get(env)]
    return kv
