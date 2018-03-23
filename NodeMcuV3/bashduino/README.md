# Intellij IDEA config

## Plugins

* bash support

## Config

* `.idea/workshpace.xml`:

    ```
    <?xml version="1.0" encoding="UTF-8"?>
    <project version="4">
      <component name="NamedScopeManager">
        <scope name="not lib" pattern="!file[IoT]:NodeMcuV3/bashduino/src/main/lib//*" />
      </component>
    </project>
    ```

* `.idea/inspectionProfiles/Project_Default.xml`:

    For not warning about local variables defined in global scope in library function files:

    ```
    <component name="InspectionProjectProfileManager">
      <profile version="1.0">
        <option name="myName" value="Project Default" />
        <inspection_tool class="BashGlobalLocalVarDef" enabled="true" level="WEAK WARNING" enabled_by_default="false">
          <scope name="not lib" level="WEAK WARNING" enabled="true" />
        </inspection_tool>
      </profile>
    </component>
    ```