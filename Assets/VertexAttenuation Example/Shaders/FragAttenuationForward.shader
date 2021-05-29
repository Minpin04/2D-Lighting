Shader "Environment/FragAttenuationForward"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"DisableBatching" = "True"
			"CanUseSpriteAtlas"="True"
		}

        LOD 100
		Lighting On
		ZWrite Off
		Fog { Mode Off }
		Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
			Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 textureSample = tex2D(_MainTex, i.uv);

				// Set ambient light as base, additional light will be added in ForwardAdd pass.
				float3 lighting = unity_AmbientSky;

				fixed4 finalColor = float4(textureSample.rgb * lighting.rgb, textureSample.a);

                return finalColor;
            }
            ENDCG
        }

		Pass
        {    
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One

            CGPROGRAM

            #pragma vertex vert  
            #pragma fragment frag 
			#pragma target 3.0

            #include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#pragma multi_compile_lightpass

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 color : COLOR;
				float3 unBatchedVertex : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float3 percivedVertexMV : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				// Note: .w is required for matrix transformation to work.
				float4 perciveblePosition = float4(v.color, 1);

				// Transform percived vertex in to World Space.
				// Note: This is different from vertex based solution becouse pixel lights are provided in world space.
				o.percivedVertexMV = mul(unity_ObjectToWorld, perciveblePosition);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 textureSample = tex2D(_MainTex, i.uv);

				float3 percivedVertexMV = i.percivedVertexMV;

				// Calculate light attenuation.
				UNITY_LIGHT_ATTENUATION(lightAttenuation, i, percivedVertexMV);
				
				fixed3 diffusedColor = textureSample.a * textureSample.rgb * _LightColor0.xyz * lightAttenuation;

                return fixed4(diffusedColor.rgb, 0);
            }
            ENDCG
		}
    }
}