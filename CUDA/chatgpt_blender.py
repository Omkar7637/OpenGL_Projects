bl_info = {
    "name": "ChatGPT Generator",
    "blender": (3, 6, 0),
    "category": "3D View",
}

import bpy
import openai

openai.api_key = "PASTE_YOUR_API_KEY_HERE"

class CHATGPT_OT_generate(bpy.types.Operator):
    bl_idname = "chatgpt.generate"
    bl_label = "Generate from Prompt"

    prompt: bpy.props.StringProperty(name="Prompt")

    def execute(self, context):
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {"role": "user", "content": f"Write Blender Python code only. {self.prompt}"}
            ]
        )

        code = response["choices"][0]["message"]["content"]
        exec(code)
        return {'FINISHED'}

class CHATGPT_PT_panel(bpy.types.Panel):
    bl_label = "ChatGPT Generator"
    bl_idname = "CHATGPT_PT_panel"
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = 'ChatGPT'

    def draw(self, context):
        layout = self.layout
        layout.prop(context.scene, "chatgpt_prompt")
        layout.operator("chatgpt.generate")

def register():
    bpy.types.Scene.chatgpt_prompt = bpy.props.StringProperty()
    bpy.utils.register_class(CHATGPT_OT_generate)
    bpy.utils.register_class(CHATGPT_PT_panel)

def unregister():
    bpy.utils.unregister_class(CHATGPT_OT_generate)
    bpy.utils.unregister_class(CHATGPT_PT_panel)

if __name__ == "__main__":
    register()
