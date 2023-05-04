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

cap_re = re.compile('(?<!^)(?=[A-Z])')
def camel_to_snake(camel):
    """Converts CamelCase separated string to snake_case.

    Args:
        camel (str): CamelCase separated string

    Returns:
        A string in snake_case.
    """
    s1 = cap_re.sub('_', camel)
    return s1.lower()
