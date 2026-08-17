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

            messages: [
              {
                role: "user",

                content: [
                  {
                    type: "text",

                    text: `
Look at this refrigerator photo.

Please identify the food ingredients that are clearly visible.

Then suggest one dish that can reasonably be made using those ingredients.

Return your answer in this format:

Ingredients detected:
- ingredient 1
- ingredient 2
- ingredient 3

Suggested Dish:
dish name

Why this dish:
short explanation

Instructions:
1. step
2. step
3. step

Please do not claim that an ingredient exists if you cannot reasonably see it.
`,
                  },

                  {
                    type: "image_url",

                    image_url: {
                      url: image
                    }
                  }
                ]
              }
            ]
          })
        }
      );

      const groqData = await groqResponse.json();

      return new Response(
        JSON.stringify(groqData),
        {
          status: groqResponse.status,

          headers: {
			...corsHeaders,
            "Content-Type": "application/json"
          }
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