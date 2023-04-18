MavenDeps = provider(
    fields = {
        "all_maven_dep_coordinates": "Array of Maven coordinates for all dependencies",
    },
)

# taken from rules_jvm_external
_ASPECT_ATTRS = [
    "deps",
    "exports",
    "runtime_deps",
]
_MAVEN_PREFIX = "maven_coordinates="
_STOP_TAGS = ["maven:compile-only", "no-maven"]

def _read_coordinates(tags):
    coordinates = []
    for stop_tag in _STOP_TAGS:
        if stop_tag in tags:
            return None

    for tag in tags:
        if tag.startswith(_MAVEN_PREFIX):
            coordinates.append(tag[len(_MAVEN_PREFIX):])

    if len(coordinates) > 1:
        fail("Zero or one set of coordinates should be defined: %s" % coordinates)

    if len(coordinates) == 1:
        return coordinates[0]

    return None

# def _maven_deps_aspect_impl(target, ctx):
#     if not JavaInfo in target:
#         return [MavenDeps(all_maven_dep_coordinates = depset())]

#     maven_coordinates = []

#     coords = _read_coordinates(ctx.rule.attr.tags)
#     print(coords)
#     # if coords and 'booking' in coords:
#     #     print('\n', ctx.rule.attr, "->", coords)
#     if coords:
#         maven_coordinates.append(coords)
#     else:
#         # TODO: decide if this is worth it or too noisy
#         # print("[!] No maven coordinates found for dep: %s" % (target.label))
#         pass

#     # this is the recursive bit of apsects, each "sub" dep will already have maven_coordinates
#     # so we keep "bubbling them up" to the final target
#     all_deps = []
#     for attr in _ASPECT_ATTRS:
#         for dep in getattr(ctx.rule.attr, attr, []):
#             all_deps.append(dep[MavenDeps].all_maven_dep_coordinates)

#     print(coords)
#     # if coords == 'com.booking.infra:infra-spring-boot:{infra-project}':
#     #     print(all_deps)

#     return MavenDeps(
#         all_maven_dep_coordinates = depset(maven_coordinates, transitive = all_deps),
#     )

def _maven_deps_aspect_impl(target, ctx):
    if not JavaInfo in target:
        return [MavenDeps(all_maven_dep_coordinates = {})]

    maven_coordinates = {}

    coords = _read_coordinates(ctx.rule.attr.tags)
    # if coords:
    #     maven_coordinates.append(coords)
    # else:
    #     # TODO: decide if this is worth it or too noisy
    #     # print("[!] No maven coordinates found for dep: %s" % (target.label))
    #     pass

    # this is the recursive bit of apsects, each "sub" dep will already have maven_coordinates
    # so we keep "bubbling them up" to the final target
    all_deps = {}
    for attr in _ASPECT_ATTRS:
        for dep in getattr(ctx.rule.attr, attr, []):
            all_deps.append(dep)
            
    maven_coordinates[coords] = all_deps

    return MavenDeps(
        all_maven_dep_coordinates = maven_coordinates,
    )

maven_deps_aspect = aspect(
    implementation = _maven_deps_aspect_impl,
    attr_aspects = _ASPECT_ATTRS,
)
