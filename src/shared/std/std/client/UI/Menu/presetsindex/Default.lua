return function(Menu)
    Menu--:UseAnimationSet("Fade", 0)
        --:UseAnimationSet("Grow", UDim2.fromScale(.001, .35)) -- ROBLOX BUG: IF YOU SHRINK CANVAGROUPS TO 0 IT STOPS DRAWING... AND DOESN'T RESUME DRAWING WHEN YOU GROW IT BACK
        :UseAnimationSet("Grow", UDim2.fromScale(0, .35))
        :UseAnimationSet("Slide", UDim2.new(0, 0, 0.2, 0))
        :UseAnimationSet("CameraFOV", 4)
        :UseAnimationSet("GameBlur", 12)

        -- :ConfigureAnimationTween("Fade", 0.18, Enum.EasingStyle.Sine)
        :ConfigureAnimationTween("Grow", 0.3*.75, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        :ConfigureAnimationTween("Slide", 0.3*.75, Enum.EasingStyle.Back)
        :ConfigureAnimationTween("CameraFOV", 0.12*0.7, Enum.EasingStyle.Circular)
        :ConfigureAnimationTween("GameBlur", 0.12*0.7, Enum.EasingStyle.Circular)

        -- :OnClose("Fade", function(setArgs, tweenArgs)
        --     task.wait(tweenArgs[1] / 1.4)
        -- end)
end