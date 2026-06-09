export type ConveyorInstance = BasePart & {
	Start: Attachment,
	End: Attachment,
}

export type SpawnIntervalSelectorGui = ScreenGui & {
	Frame: Frame & {
		Bar: Frame,
		Hold: Frame & {
			UIDragDetector: UIDragDetector,
		},
	},
	Maximum: TextLabel,
	Minimum: TextLabel,
	Current: TextLabel,
}

return nil
