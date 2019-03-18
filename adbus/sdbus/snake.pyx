# Copyright: 2017, CCX Technologies
#cython: language_level=3

def snake_to_camel(snake):
    """Converts a snake_case string to CamelCase.

    Args:
        snake (str): Underscore separated string

    Returns:
        A string in CamelCase.
    """
    return "".join(x[:1].upper() + x[1:] for x in snake.split("_"))

first_cap_re = re.compile('(.)([A-Z][a-z]+)')
all_cap_re = re.compile('([a-z0-9])([A-Z])')
def camel_to_snake(camel):
    """Converts CamelCase separated string to snake_case.

    Args:
        camel (str): CamelCase separated string

    Returns:
        A string in snake_case.
    """
    s1 = first_cap_re.sub(r'\1_\2', camel)
    return all_cap_re.sub(r'\1_\2', s1).lower()
