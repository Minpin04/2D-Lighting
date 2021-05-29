Shader "Environment/FragAttenuation"
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

            #include "UnityCG.cginc"

			#define MaxLights 4

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

				// Transform percived vertex in to Model-View Space.
				// Note: Unity stores 8 vertex lights position in MV space, to calculate distance we shold transform vertex in to MV as well.
				o.percivedVertexMV = mul(UNITY_MATRIX_MV, perciveblePosition);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 textureSample = tex2D(_MainTex, i.uv);

				float3 percivedVertexMV = i.percivedVertexMV;

				// Calculate light.
				// Set ambient light as base, loop and add light sources attenuation.
				float3 lighting = unity_AmbientSky;

				for (int index = 0; index < MaxLights; index++)
				{  
					float3 vertexToLightSource = unity_LightPosition[index].xyz - percivedVertexMV;    
					float squaredDistance = dot(vertexToLightSource, vertexToLightSource);
					float lightRange = unity_LightAtten[index].b;
					float attenuation = 1.0 / (1.0 + lightRange * squaredDistance * squaredDistance);
				
					float3 attenuatedColor = attenuation * unity_LightColor[index].rgb;
 				
					lighting += attenuatedColor;
				}

				fixed4 finalColor = float4(textureSample.rgb * lighting.rgb, textureSample.a);

                return finalColor;
            }
            ENDCG
        }
    }
}
