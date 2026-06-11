# SwiftGlow Demo UI/UX prototype.

```tsx
<Window>
  <SidePanel>
    <Presets>
      <SectionHeader title="Presets" right={<Button size="tiny">Import</Button>}/>
      <PresetsGrid columns={2} />
    </Presets>
    <Status>
      <SectionHeader title="Presets"/>
      {/*No Title*/}
      <StatusTab>
        <TabItem active>Default</TabItem>
        <TabItem>Hover</TabItem>
        <TabItem>Press</TabItem>
      </StatusTab>
    </Status>
    <Layers>
      <Layer index={0}>
        {/* LayerTitleRow 显示标题、展开收起按钮、禁用启用复选框、删除按钮 */}
        <LayerTitleRow  />
        <LayerParams />
      </Layer>
      {/*more layers*/}
    </Layers>
    <BottomActions>
      <ButtonCopyAsReactNativeGlowJSON />
      <ButtonCopySwiftGlowConfig />
    </BottomActions>
  </SidePanel>
  <Preview/>
</Window>
```
