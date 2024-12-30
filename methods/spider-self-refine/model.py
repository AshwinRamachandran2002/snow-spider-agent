from openai import OpenAI, AzureOpenAI
from utils import extract_all_blocks
import os

class GPTChat:
    def __init__(self, azure=False, model="gpt-4o") -> None:
        if model in ["gpt-4o", "o1-2024-12-17"] or not azure:
            self.client = OpenAI(
                api_key=os.environ.get("OPENAI_API_KEY"),  # This is the default and can be omitted
            )
        else:
            self.client = AzureOpenAI(
                azure_endpoint = os.environ.get("AZURE_ENDPOIONT"),
                api_key=os.environ.get("AZURE_OPENAI_KEY"),  # This is the default and can be omitted
                api_version="2024-02-15-preview"
            )

        self.messages = []
        self.model = model

    def get_model_response(self, prompt, code_format):
        self.messages.append({"role": "user", "content": prompt})
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=self.messages
            )
        except Exception as e:
            print(e)
            return "Exceeded"
        choices = response.choices
        if choices:
            # Extract the main message content
            main_content = choices[0].message.content
            # print("Main Content:\n", main_content)
            
            sql_query = extract_all_blocks(main_content, code_format)
        self.messages.append({"role": "assistant", "content": main_content})
        # print(f"Current_context_len: {self.get_message_len()}")
        return sql_query
    def get_model_response_txt(self, prompt):
        self.messages.append({"role": "user", "content": prompt})
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=self.messages
            )
        except Exception as e:
            print(e)
            return "Exceeded"
        choices = response.choices
        if choices:
            # Extract the main message content
            main_content = choices[0].message.content
            # print("Main Content:\n", main_content)
            
            # sql_query = extract_all_sql_blocks(main_content)
        self.messages.append({"role": "assistant", "content": main_content})
        # print(f"Current_context_len: {self.get_message_len()}")
        return main_content

    def get_message_len(self):
        return sum([len(i['content']) for i in self.messages])
    
    def init_messages(self):
        self.messages = []

class modelChat():
    def __init__(self, model, tokenizer) -> None:
        self.model = model
        self.tokenizer = tokenizer
        self.messages = []

    def get_model_response(self, prompt, code_format):
        self.messages.append({"role": "user", "content": prompt})
        text = self.tokenizer.apply_chat_template(
            self.messages,
            tokenize=False,
            add_generation_prompt=True
        )
        model_inputs = self.tokenizer([text], return_tensors="pt").to(self.model.device)

        generated_ids = self.model.generate(
            **model_inputs,
            max_new_tokens=512
        )
        generated_ids = [
            output_ids[len(input_ids):] for input_ids, output_ids in zip(model_inputs.input_ids, generated_ids)
        ]

        response = self.tokenizer.batch_decode(generated_ids, skip_special_tokens=True)[0]
        sql_query = extract_all_blocks(response)
        self.messages.append({"role": "assistant", "content": response})
        return sql_query

    def get_message_len(self):
        return sum([len(i['content']) for i in self.messages])

    def init_messages(self):
        self.messages = []