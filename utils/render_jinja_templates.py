import os
import sys
import yaml
from jinja2 import Environment, FileSystemLoader


def render(template, vars_file):
    """
    :param template: Path to jinja2 template, yaml format
    :return: string representation of the rendered jinja template
    """

    env_dir = os.path.dirname(template)
    env_dir = os.getcwd() if env_dir == '' else env_dir
    env = Environment(loader=FileSystemLoader(env_dir))
    template = env.get_template(os.path.basename(template))
    context = {}

    # Load vars
    if vars_file:
        with open(vars_file) as f:
            context.update(yaml.load(f))

    # Make the shell environment accessible as variable 'env'
    context.update(os.environ)
    return template.render(**context)

if __name__ == '__main__':
    if len(sys.argv) < 2:

        print ("Usage: %s path to jinja2 template [path to vars_file]" % sys.argv[0])
        sys.exit(1)

    vars_file = None
    if len(sys.argv) > 2 and os.path.isdir(sys.argv[2]):
        vars_file = sys.argv[2]

    print render(sys.argv[1], vars_file)
