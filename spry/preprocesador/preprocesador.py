
import re
from pathlib import Path

MAX_INCLUDE_DEPTH = 10
_INCLUDE = re.compile(r'^\s*#\s*include\s*"([^"]+)"\s*$')
_DEFINE = re.compile(r"^\s*#\s*define\s+([A-Za-z_][A-Za-z0-9_]*)(?:[ \t]+(.*))?$")
_IDENTIFIER = re.compile(r"\b[A-Za-z_][A-Za-z0-9_]*\b")


def preprocess_file(path):
    """Preprocesa *path*, resolviendo includes relativos al archivo actual."""
    return preprocess(Path(path).read_text(encoding="utf-8"), Path(path).parent, Path(path))


def preprocess(text, base_dir=None, source_name="<entrada>"):
    macros = {}
    base_dir = Path(base_dir or ".")

    def expand(value, resolving=()):
        def replace(match):
            name = match.group(0)
            if name not in macros or name in resolving:
                return name
            return expand(macros[name], resolving + (name,))

        return _IDENTIFIER.sub(replace, value)

    def process(contents, directory, name, depth):
        if depth > MAX_INCLUDE_DEPTH:
            raise ValueError(
                f"Se excedió el límite de inclusión ({MAX_INCLUDE_DEPTH}) en {name}"
            )

        output = []
        for line_number, line in enumerate(contents.splitlines(keepends=True), 1):
            include = _INCLUDE.match(line.rstrip("\r\n"))
            if include:
                include_path = Path(include.group(1))
                if not include_path.is_absolute():
                    include_path = directory / include_path
                try:
                    included_text = include_path.read_text(encoding="utf-8")
                except OSError as error:
                    raise ValueError(
                        f"No se pudo incluir '{include.group(1)}' desde "
                        f"{name}:{line_number}: {error}"
                    ) from error
                output.append(
                    process(
                        included_text,
                        include_path.parent,
                        str(include_path),
                        depth + 1,
                    )
                )
                continue

            define = _DEFINE.match(line.rstrip("\r\n"))
            if define:
                macros[define.group(1)] = define.group(2) or ""
                continue

            output.append(expand(line))
        return "".join(output)

    return process(text, base_dir, str(source_name), 0)
