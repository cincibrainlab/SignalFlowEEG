import matplotlib.pyplot as plt



import numpy as np

# def sort_and_shift_lists(x, y):
#     # Sort x and get the corresponding indices
#     x = [int(g) for g in x]
#     sorted_indices = np.argsort(x)
#     sorted_x = np.sort(x)
    
#     # Shift the order of y based on the sorted indices
#     shifted_y = [y[i] for i in sorted_indices]

#     return sorted_x, shifted_y

# y = {'Ch 01',	'Ch 02',	'Ch 03',	'Ch 04',	'Ch 05',	'Ch 06',	'Ch 07',	'Ch 08',	'Ch 09', 'Ch 10',	'Ch 11', 'Ch 12',	'Ch 13',	'Ch 14',	'Ch 15',	'Ch 16',	'Ch 17',	'Ch 18',	'Ch 19', 'Ch 20',    'Ch 21',	'Ch 22',	'Ch 23',	'Ch 24',	'Ch 25',	'Ch 26',	'Ch 27',	'Ch 28',	'Ch 29', 'Ch 30'};
# x = {'30',	'28',	'26',	'24',	'22',	'20',	'18',	'31',	'29',	'27',	'25',	'23',	'21',	'19', '17',	'15',	'13',	'11',	'9',	'7',	'5',	'3',	'1',	'16',	'14',	'12',	'10',	'8',	'6', '4'};

# sorted_x, shifted_y = sort_and_shift_lists(x, y)

# print(sorted_x)   
# print(shifted_y)  

def plot_scaled_scatter_with_names(x, y, names):
    plt.scatter(x, y)
    plt.xlabel('X')
    plt.ylabel('Y')
    plt.title('Scaled Scatter Plot of X and Y')
    plt.axis('scaled')

    # Add names for each point
    for i, name in enumerate(names):
        plt.text(x[i], y[i], name, ha='center', va='bottom')

    plt.axis('scaled')
    plt.show()


y = [699.11361,699.11361,699.11361,589.11361,589.11361,589.11361,481.11361,481.11361,481.11361,333.11361,333.11361,181.11439000000001,181.11439000000001,55.11439,55.11439,55.11439,55.11439,181.11439000000001,181.11439000000001,333.11361,333.11361,481.11361,481.11361,481.11361,589.11361,589.11361,589.11361,699.11361,699.11361,699.11361,0,0,0,0,0,0,0,0]
x = [404.99960999999996,223.99961,99.99960999999999,412.99961,287.99960999999996,112.99961,404.99960999999996,287.99960999999996,111.99961,349.99960999999996,211.99961,192.99961000000002,54.99961,149.99961000000002,49.999610000000004,-49.999610000000004,-149.99961000000002,-54.99961,-192.99961000000002,-211.99961,-349.99960999999996,-111.99961,-287.99960999999996,-404.99960999999996,-112.99961,-287.99960999999996,-412.99961,-99.99960999999999,-223.99961,-404.99960999999996,0,0,0,0,0,0,0,0]


names = ["pri_0","pri_1","pri_2","pri_3","pri_4","pri_5","pri_6","pri_7","pri_8","pri_9","pri_10","pri_11","pri_12","pri_13","pri_14","pri_15","pri_16","pri_17","pri_18","pri_19","pri_20","pri_21","pri_22","pri_23","pri_24","pri_25","pri_26","pri_27","pri_28","pri_29","pri_30","pri_31","aux_0","aux_1","din_0","din_1","dout_0","dout_1"]
dummyNumber = [str(i+1) for i in range(len(x))]
y = [-val for val in y]
x = [-val for val in x]
# plot_scaled_scatter_with_names(x, y, names)
plot_scaled_scatter_with_names(x, y, dummyNumber)


