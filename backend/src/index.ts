const corsHeaders = {
		"Access-Control-Allow-Origin": "*",
		"Access-Control-Allow-Methods": "GET, POST, OPTIONS",
		"Access-Control-Allow-Headers": "Content-Type",
	};

export default {
  async fetch(request, env, ctx): Promise<Response> {
	

	if(request.method === "OPTIONS") {
		return new Response(null, {
			headers: corsHeaders,
		});
	}

    // Allow GET requests for a simple health check
    if (request.method === "GET") {
      return new Response(
        JSON.stringify({
          status: "Snapshot Chef backend is running"
        }),
        {
          headers: {
			...corsHeaders,
            "Content-Type": "application/json"
          }
        }
      );
    }

    // Only allow POST requests for image analysis
    if (request.method !== "POST") {
      return new Response(
        JSON.stringify({
          error: "Only POST requests are allowed."
        }),
        {
          status: 405,
          headers: {
			...corsHeaders,
            "Content-Type": "application/json",
          }
        }
      );
    }

    try {
      const body = await request.json();

      const image = body.image;

      if (!image) {
        return new Response(
          JSON.stringify({
            error: "No image was provided."
          }),
          {
            status: 400,
            headers: {
				...corsHeaders,
              "Content-Type": "application/json",
            }
          }
        );
      }

      const groqResponse = await fetch(
        "https://api.groq.com/openai/v1/chat/completions",
        {
          method: "POST",

          headers: {
            "Authorization": `Bearer ${env.GROQ_API_KEY}`,
            "Content-Type": "application/json"
          },

          body: JSON.stringify({
            model: "qwen/qwen3.6-27b",

			reasoning_effort: "none",
			reasoning_format: "hidden",

			temperature: 0.2,

			
            messages: [
              {
                role: "user",

                content: [
                  {
                    type: "text",

                    text: `
You are the recipe engine for Snapshot Chef.

Analyze the refrigerator photo and identify only food ingredients that are clearly visible.

Then create ONE practical dish that can reasonably be made using those ingredients.

Rules:
- Do not invent ingredients.
- Only include ingredients that you can reasonably see.
- You may assume basic cooking necessities such as water, salt, and cooking oil.
- Prefer recipes that use several detected ingredients.
- Keep the recipe practical and simple.
- If there are not enough ingredients for a complete dish, explain this briefly in the "why" field.
- Do not include introductions.
- Do not include conclusions.
- Do not include conversational text.
- Do not use Markdown.
- Do not use asterisks.
- Do not include <think> or reasoning.
- Return ONLY valid JSON.

The JSON MUST contain all five fields below.

Every field is REQUIRED.

"ingredients" MUST always be an array of strings.
"instructions" MUST always be an array of strings.

Never return null for any field.

Even if no ingredients are confidently detected, return:
"ingredients": []

Even if no useful tip exists, return:
"tip": "None"

Return ONLY the JSON object.
Do not include <think>.
Do not include Markdown.
Do not include text before or after the JSON.:

{
  "dish": "name of dish",
  "ingredients": [
    "ingredient 1",
    "ingredient 2",
    "ingredient 3"
  ],
  "why": "short explanation",
  "instructions": [
    "step 1",
    "step 2",
    "step 3",
    "step 4"
  ],
  "tip": "one useful cooking tip"
}
`,
                  },

                  {
                    type: "image_url",

                    image_url: {
                      url: image
                    },
                  },
                ],
              },
            ],

			response_format: {
				type: "json_object",
			},
          }),
        }
      );

      const groqData = await groqResponse.json();

	  const content = 
	  	groqData.choices?.[0]?.message?.content;

	  if(!content) {
		return new Response(
			JSON.stringify({
				error: "Groq did not return a recipe",
			}),
			{
				status: 500,
				headers: {
					...corsHeaders,
					"Content-Type": "application/json",
				},
			}
		);
	  }

	  let recipe;

	  try {
		recipe = JSON.parse(content);
	  } catch (error) {
		if (
			!recipe ||
			typeof recipe.dish !== "string" ||
			!Array.isArray(recipe.ingredients) ||
			typeof recipe.why != "string" ||
			!Array.isArray(recipe.instructions) ||
			typeof recipe.tip !== "string" 
		) {
			return new Response(
				JSON.stringify({
					error: "Groq returned an incomplete recipe.",
					raw: recipe,
				}),
				{
					status: 500,
					headers: {
						...corsHeaders,
						"Content-Type": "application/json",
					},
				}
			);
		}

		return new Response(
			JSON.stringify({
				error: "Groq returned invalid JSON.",
			}),
			{
				status: 500,
				headers: {
					...corsHeaders,
					"Content-Type": "application/json",
				},
			}
		);
	  }
	  
	  return new Response(
		JSON.stringify(recipe),
		{
			status: 200,
			headers: {
				...corsHeaders,
				"Content-Type": "application/json",
			},
		}
	  );
      

    } catch (error) {

      return new Response(
        JSON.stringify({
          error: "Something went wrong."
        }),
        {
          status: 500,

          headers: {
			...corsHeaders,
            "Content-Type": "application/json",
          }
        }
      );
    }
  }
};