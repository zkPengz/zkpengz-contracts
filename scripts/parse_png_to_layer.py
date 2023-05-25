#!/usr/bin/python3
import json
import os
from functools import reduce
from PIL import Image
from string import ascii_lowercase
from dotenv import load_dotenv

load_dotenv()

LETTERS = {index: letter for index, letter in enumerate(ascii_lowercase, start=0)}


def rgb2hex(r, g, b):
    return '#{:02x}{:02x}{:02x}'.format(r, g, b)


def main():
    path = './assets/layers'
    folders = os.listdir('./assets/layers')
    folders.sort()
    colors = []
    colors_str = ''

    cid = 0
    for folder in folders:
        layers = os.listdir('./assets/layers/' + folder)
        layers.sort()
        for layer in layers:
            file_name = path + '/' + folder + '/' + layer
            img = Image.open(file_name)
            for x in range(0, img.width):
                for y in range(0, img.width):
                    color_tuple = img.getpixel((x, y))
                    if len(color_tuple) == 4:
                        (r, g, b, a) = color_tuple
                    else:
                        (r, g, b) = color_tuple
                        a = 1
                    hex_color = rgb2hex(r, g, b)
                    if a > 0 and hex_color not in colors:
                        colors.append(hex_color)
                        colors_str += '.c' + str(cid).zfill(3) + '{fill:' + hex_color + '}'
                        cid += 1

    color_file = open("./assets/colors.txt", "wt")
    color_file.write(colors_str)
    color_file.close()

    full_data = []
    tiers = []
    tiers_arr = []

    for folder in folders:
        folder_params = folder.split('_')
        layer_type_id = int(folder_params[0])

        layers = os.listdir('./assets/layers/' + folder)
        layers.sort()
        layer_data = []
        layer_probs = []
        layer_probs_int = []
        for layer in layers:
            all_params = layer.split('.')
            file_name = path + '/' + folder + '/' + layer

            pixel_data = ''
            layer_name = all_params[0].split('#')[0]
            layer_prob = all_params[0].split('#')[1]
            layer_prob_int = int(all_params[0].split('#')[1])

            layer_probs.append(layer_prob)
            layer_probs_int.append(layer_prob_int)
            img = Image.open(file_name)

            for y in range(0, img.width):
                prev_color = None
                line_width = 0
                new_line = True
                for x in range(0, img.height):
                    color_tuple = img.getpixel((x, y))
                    if len(color_tuple) == 4:
                        (r, g, b, a) = color_tuple
                    else:
                        (r, g, b) = color_tuple
                        a = 1
                    hex_color = rgb2hex(r, g, b) if a > 0 else None

                    color_changed = prev_color != hex_color
                    last_pixel = x + 1 == img.width

                    if line_width > 0 and ((color_changed and not new_line) or last_pixel) and prev_color is not None:
                        pixel_data += LETTERS[x - line_width]
                        pixel_data += LETTERS[y]
                        pixel_data += LETTERS[line_width + 1 if (last_pixel and not color_changed) else line_width]
                        pixel_data += str(colors.index(prev_color)).zfill(3)
                        line_width = 0

                    if last_pixel and hex_color and color_changed and line_width == 0:
                        pixel_data += LETTERS[x]
                        pixel_data += LETTERS[y]
                        pixel_data += LETTERS[1]
                        pixel_data += str(colors.index(hex_color)).zfill(3)

                    if color_changed:
                        line_width = 0

                    new_line = False
                    line_width += 1
                    prev_color = hex_color

            layer_data.append({
                'layerName': layer_name,
                'pixels': pixel_data,
            })

        full_data.append({
            'id': layer_type_id,
            'data': layer_data
        })

        sum_prob = reduce(lambda a, b: int(a)+int(b), layer_probs_int)
        if sum_prob != 3333:
            print(f'wrong probability {sum_prob} in layer {folder}')

        tiers.append(f"// {folder}")
        tiers.append(f"TIERS[{layer_type_id}] = [{', '.join(layer_probs)}];")
        tiers_arr.append(layer_probs_int)

    tiers_file = open("./assets/tiers.txt", "wt")
    tiers_file.write("\n".join(tiers))
    tiers_file.close()

    tiers_file2 = open("./assets/tiers.json", "wt")
    tiers_file2.write(json.dumps(tiers_arr))
    tiers_file2.close()

    layer_file = open("./assets/layers.json", "wt")
    layer_file.write(json.dumps(full_data))
    layer_file.close()


if __name__ == '__main__':
    main()
