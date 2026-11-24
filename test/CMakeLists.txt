configure_lit_site_cfg(
        ${CMAKE_CURRENT_SOURCE_DIR}/lit.site.cfg.py.in
        ${CMAKE_CURRENT_BINARY_DIR}/lit.site.cfg.py
        MAIN_CONFIG
        ${CMAKE_CURRENT_SOURCE_DIR}/lit.cfg.py
)

set(MYDIALECT_TEST_DEPENDS
        FileCheck count not
        my-opt
        )

add_lit_testsuite(check-mydialect "Running the mydialect regression tests"
        ${CMAKE_CURRENT_BINARY_DIR}
        DEPENDS ${MYDIALECT_TEST_DEPENDS}
)

set_target_properties(check-mydialect PROPERTIES FOLDER "Tests")
