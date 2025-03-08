import os
import math
import multiprocessing as mp
import traceback
import jsonlines
from tqdm import tqdm


def read_jsonl_file(file_name, max_sentence=None):
    data = []
    with jsonlines.open(file_name, "r") as r:
        for i, obj in tqdm.tqdm(enumerate(r)):
            if max_sentence is not None and i >= max_sentence:
                return data
            data.append(obj)
    return data

class MPLogExceptions(object):
    def __init__(self, callable):
        self.__callable = callable

    def error(msg, *args):
        return mp.get_logger().error(msg, *args) 

    def __call__(self, *args, **kwargs):
        try:
            result = self.__callable(*args, **kwargs)

        except Exception as e:
            # Here we add some debugging help. If multiprocessing's
            # debugging is on, it will arrange to log the traceback
            self.error(traceback.format_exc())
            # Re-raise the original exception so the Pool worker can``
            # clean up
            raise

        # It was fine, give a normal answer
        return result

def find_next_line(f, position):
    if position == 0:
        return position
    f.seek(position)
    f.readline()
    position = f.tell()
    return position

def multi_tasks_from_file(file_name = 'example.txt', workers = 16, chunk_size = None, task = None, args = None):    
    file_size = os.path.getsize(file_name)
    print(f"The size of {file_name} is: {file_size} bytes")
    if chunk_size:
        assert chunk_size > 0
        job_num = math.ceil(float(file_size) / chunk_size)
        positions = [chunk_size * i for i in range(job_num)]
        start_positions = [(file_name, positions[i], positions[i] + chunk_size, i, args) for i in range(job_num)]
        print(f"job num: {job_num}")
    else:
        chunk_size = math.ceil(float(file_size) / workers)
        positions = [chunk_size * i for i in range(workers)]
        start_positions = [(file_name, positions[i], positions[i] + chunk_size, i, args) for i in range(workers)]
    p = mp.Pool(workers)
    results = []
    for pos in start_positions:
        results.append(p.apply_async(MPLogExceptions(task), args=(pos,)))
    p.close()
    p.join()
    output_objs = []
    for result in results:
        output_objs.extend(result.get())
    print(f"Successfully Loading from {file_name}: {len(output_objs)} samples")
    return output_objs
