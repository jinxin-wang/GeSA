from snakemake.utils import min_version
import yaml

min_version("5.4.0")

configfile: "config/config.yaml"

FILEPATHS = yaml.load(open(config["filepaths"]["yaml"], "r"), Loader=yaml.FullLoader)

#### Helper functions ####
def get_mutations_file(w):
    if w.selection == "annotated":
        return config["data"]["mut"]["ann"][w.cohort]
    else:
        return config["data"]["mut"]["all"][w.cohort]

