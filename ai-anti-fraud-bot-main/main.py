import openai
from dotenv import find_dotenv, load_dotenv
import time
import logging
from datetime import datetime

load_dotenv()

client = openai.OpenAI()
model = "gpt-4o-mini"

# === Thread ===
# thread = client.beta.threads.create(
#     messages=[
#         {
#             "role": "user",
#             "content": "你可以幫我辨識錄音逐字搞是不是詐騙嗎?"
#         }
#     ]
# )
# thread_id = thread.id
# print(thread_id)

# === Hardcode our ids ===
asistant_id = "asst_uzEmFHU9WUxWyQZ0vpCJBEDV"
thread_id = "thread_a3JuN3SEAKwKDj0zqv7vGWWC"

# === Create a Message ===
message = """欸媽我今天晚上不回家吃飯喔不用煮我的
你還在同學家嗎
對阿
我等等應該九點多才會回家
好等等回來要注意安全喔
好掰掰
掰掰"""
message = client.beta.threads.messages.create(
    thread_id=thread_id, role="user", content=message
)

# === Run our Assistant ===
run = client.beta.threads.runs.create(
    thread_id=thread_id,
    assistant_id=asistant_id,
    instructions="",
)

def wait_for_run_completion(client, thread_id, run_id, sleep_interval=5):
    """
    Waits for a run to complete and prints the elapsed time.:param client: The OpenAI client object.
    :param thread_id: The ID of the thread.
    :param run_id: The ID of the run.
    :param sleep_interval: Time in seconds to wait between checks.
    """
    while True:
        try:
            run = client.beta.threads.runs.retrieve(thread_id=thread_id, run_id=run_id)
            if run.completed_at:
                elapsed_time = run.completed_at - run.created_at
                formatted_elapsed_time = time.strftime(
                    "%H:%M:%S", time.gmtime(elapsed_time)
                )
                print(f"Run completed in {formatted_elapsed_time}")
                logging.info(f"Run completed in {formatted_elapsed_time}")
                # Get messages here once Run is completed!
                messages = client.beta.threads.messages.list(thread_id=thread_id)
                last_message = messages.data[0]
                response = last_message.content[0].text.value
                print(f"Assistant Response: {response}")
                break
        except Exception as e:
            logging.error(f"An error occurred while retrieving the run: {e}")
            break
        logging.info("Waiting for run to complete...")
        time.sleep(sleep_interval)

# === Run ===
wait_for_run_completion(client=client, thread_id=thread_id, run_id=run.id)

# ==== Steps --- Logs ==
run_steps = client.beta.threads.runs.steps.list(thread_id=thread_id, run_id=run.id)
# print(f"Steps---> {run_steps.data[0]}")