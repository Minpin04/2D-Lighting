// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Lighting/VertexLighting"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}
		SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"DisableBatching" = "True"
			"LightMode" = "ForwardBase"
		}

		LOD 100
		Lighting On
		ZWrite Off
		Fog { Mode Off }
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 4.5

			#include "UnityCG.cginc"

			#define MaxLights 4

			RWStructuredBuffer<float4> buffer : register(u1);

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 color : COLOR;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 lightColor : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				// Note: .w is required for matrix transformation to work.
				float4 perciveblePosition = float4(v.color, 1);

				// Transform percived vertex in to Model-View Space.
				// Note: Unity stores 8 vertex lights position in MV space, to calculate distance we shold transform vertex in to MV as well.
				float3 percivedVertexMV = mul(UNITY_MATRIX_MV, perciveblePosition);

				// Calculate light.
				// Set ambient light as base, loop and add light sources attenuation.
				float3 vertexLighting = unity_AmbientSky;


				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					for (int index = 0; index < MaxLights; index++)
					{
					float3 lightPos = float3(unity_4LightPosX0[index], unity_4LightPosY0[index], unity_4LightPosZ0[index]);
					
					float3 vertexToLightSource = lightPos - worldPos;
					if (index == 0)
					buffer[0] = float4(lightPos,0);
					float squaredDistance = dot(vertexToLightSource, vertexToLightSource);
					float lightRange = unity_4LightAtten0[index];
					float attenuation = 1.0 / (1.0 + lightRange * squaredDistance * squaredDistance);

					float3 attenuatedColor = attenuation * unity_LightColor[index].rgb;

					if (lightPos.y < worldPos.y) {
						vertexLighting += attenuatedColor;
					}
				}

				o.lightColor = vertexLighting;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 textureSample = tex2D(_MainTex, i.uv);

				fixed4 finalColor = float4(textureSample.rgb * i.lightColor.rgb, textureSample.a);

				return finalColor;
			}
			ENDCG
		}
	}
}
